package com.gencel.backend.service;

import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import com.gencel.backend.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService")
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtService jwtService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    private User studentUser;
    private User adminUser;
    private LoginRequest loginRequest;

    @BeforeEach
    void setUp() {
        Institution inst = Institution.builder().id(java.util.UUID.randomUUID()).build();
        studentUser = User.builder()
                .id(java.util.UUID.randomUUID())
                .institution(inst)
                .role(User.UserRole.STUDENT)
                .email("student@test.com")
                .passwordHash("$2a$10$hashed")
                .isActive(true)
                .build();
        adminUser = User.builder()
                .id(java.util.UUID.randomUUID())
                .institution(inst)
                .role(User.UserRole.INSTITUTION_ADMIN)
                .email("admin@kurum.gov.tr")
                .passwordHash("$2a$10$hashed")
                .isActive(true)
                .build();
        loginRequest = LoginRequest.builder()
                .email("student@test.com")
                .password("password123")
                .build();
    }

    @Nested
    @DisplayName("userLogin (STUDENT/ELDERLY)")
    class UserLogin {

        @Test
        @DisplayName("geçerli student ile giriş başarılı")
        void shouldLoginStudentSuccessfully() {
            when(userRepository.findByEmailIncludingDisabled("student@test.com")).thenReturn(Optional.of(studentUser));
            when(passwordEncoder.matches("password123", studentUser.getPasswordHash())).thenReturn(true);
            when(jwtService.generateToken(any(UserDetails.class))).thenReturn("jwt-token");

            LoginResponse response = authService.userLogin(loginRequest);

            assertThat(response).isNotNull();
            assertThat(response.getToken()).isEqualTo("jwt-token");
            assertThat(response.getEmail()).isEqualTo("student@test.com");
            assertThat(response.getRole()).isEqualTo("STUDENT");
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN ile userLogin başarısız olur")
        void shouldRejectInstitutionAdminForUserLogin() {
            when(userRepository.findByEmailIncludingDisabled("admin@kurum.gov.tr")).thenReturn(Optional.of(adminUser));
            loginRequest.setEmail("admin@kurum.gov.tr");
            // Role kontrolü şifre kontrolünden önce yapılır, password stub gerekmez

            assertThatThrownBy(() -> authService.userLogin(loginRequest))
                    .isInstanceOf(org.springframework.security.authentication.BadCredentialsException.class);
        }

        @Test
        @DisplayName("kullanıcı bulunamazsa exception")
        void shouldThrowWhenUserNotFound() {
            when(userRepository.findByEmailIncludingDisabled("unknown@test.com")).thenReturn(Optional.empty());
            loginRequest.setEmail("unknown@test.com");

            assertThatThrownBy(() -> authService.userLogin(loginRequest))
                    .isInstanceOf(org.springframework.security.core.userdetails.UsernameNotFoundException.class);
        }

        @Test
        @DisplayName("yanlış şifre ile exception")
        void shouldThrowWhenWrongPassword() {
            when(userRepository.findByEmailIncludingDisabled("student@test.com")).thenReturn(Optional.of(studentUser));
            when(passwordEncoder.matches("wrong", studentUser.getPasswordHash())).thenReturn(false);
            loginRequest.setPassword("wrong");

            assertThatThrownBy(() -> authService.userLogin(loginRequest))
                    .isInstanceOf(org.springframework.security.authentication.BadCredentialsException.class);
        }

        @Test
        @DisplayName("pasif kullanıcı giriş yapamaz")
        void shouldThrowWhenUserDisabled() {
            studentUser.setIsActive(false);
            when(userRepository.findByEmailIncludingDisabled("student@test.com")).thenReturn(Optional.of(studentUser));
            // isActive kontrolü şifre kontrolünden önce yapılır, password stub gerekmez

            assertThatThrownBy(() -> authService.userLogin(loginRequest))
                    .isInstanceOf(org.springframework.security.authentication.DisabledException.class);
        }
    }

    @Nested
    @DisplayName("institutionLogin (INSTITUTION_ADMIN)")
    class InstitutionLogin {

        @Test
        @DisplayName("geçerli admin ile giriş başarılı")
        void shouldLoginAdminSuccessfully() {
            loginRequest.setEmail("admin@kurum.gov.tr");
            loginRequest.setPassword("adminpass");
            when(userRepository.findByEmailIncludingDisabled("admin@kurum.gov.tr")).thenReturn(Optional.of(adminUser));
            when(passwordEncoder.matches("adminpass", adminUser.getPasswordHash())).thenReturn(true);
            when(jwtService.generateToken(any(UserDetails.class))).thenReturn("admin-jwt");

            LoginResponse response = authService.institutionLogin(loginRequest);

            assertThat(response.getToken()).isEqualTo("admin-jwt");
            assertThat(response.getEmail()).isEqualTo("admin@kurum.gov.tr");
            assertThat(response.getRole()).isEqualTo("INSTITUTION_ADMIN");
        }

        @Test
        @DisplayName("STUDENT ile institutionLogin başarısız")
        void shouldRejectStudentForInstitutionLogin() {
            when(userRepository.findByEmailIncludingDisabled("student@test.com")).thenReturn(Optional.of(studentUser));
            // Role kontrolü şifre kontrolünden önce yapılır, password stub gerekmez

            assertThatThrownBy(() -> authService.institutionLogin(loginRequest))
                    .isInstanceOf(org.springframework.security.authentication.BadCredentialsException.class);
        }
    }
}
