package com.gencel.backend.service;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserService")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private Institution institution;
    private User institutionAdmin;
    private CreateUserRequest createStudentRequest;

    @BeforeEach
    void setUp() {
        institution = Institution.builder()
                .id(UUID.randomUUID())
                .name("Test Kurumu")
                .region("Ankara")
                .build();

        institutionAdmin = User.builder()
                .id(UUID.randomUUID())
                .institution(institution)
                .role(User.UserRole.INSTITUTION_ADMIN)
                .email("admin@kurum.gov.tr")
                .passwordHash("encoded")
                .firstName("Admin")
                .lastName("User")
                .isActive(true)
                .build();

        createStudentRequest = CreateUserRequest.builder()
                .role(User.UserRole.STUDENT)
                .firstName("Ahmet")
                .lastName("Yılmaz")
                .email("ahmet@test.com")
                .phoneNumber("0532 123 45 67")
                .password("SecurePass123")
                .iban("TR00 0000 0000 0000 0000 0000 00")
                .build();
    }

    @Nested
    @DisplayName("createUser")
    class CreateUser {

        @Test
        @DisplayName("INSTITUTION_ADMIN ile geçerli STUDENT oluşturur")
        void shouldCreateStudentWhenAdminValid() {
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());
            when(passwordEncoder.encode(anyString())).thenReturn("encoded123");

            User savedStudent = User.builder()
                    .id(UUID.randomUUID())
                    .institution(institution)
                    .role(User.UserRole.STUDENT)
                    .email(createStudentRequest.getEmail())
                    .firstName(createStudentRequest.getFirstName())
                    .lastName(createStudentRequest.getLastName())
                    .iban(createStudentRequest.getIban())
                    .build();
            when(userRepository.save(any(User.class))).thenReturn(savedStudent);

            UserResponse response = userService.createUser("admin@kurum.gov.tr", createStudentRequest);

            assertThat(response).isNotNull();
            assertThat(response.getId()).isEqualTo(savedStudent.getId());
            assertThat(response.getEmail()).isEqualTo("ahmet@test.com");
            assertThat(response.getRole()).isEqualTo(User.UserRole.STUDENT);
            verify(userRepository).save(any(User.class));
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN ile geçerli ELDERLY oluşturur (IBAN olmadan)")
        void shouldCreateElderlyWhenAdminValid() {
            createStudentRequest.setRole(User.UserRole.ELDERLY);
            createStudentRequest.setIban(null);

            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());
            when(passwordEncoder.encode(anyString())).thenReturn("encoded123");

            User savedElderly = User.builder().id(UUID.randomUUID()).role(User.UserRole.ELDERLY).build();
            when(userRepository.save(any(User.class))).thenReturn(savedElderly);

            UserResponse response = userService.createUser("admin@kurum.gov.tr", createStudentRequest);

            assertThat(response.getRole()).isEqualTo(User.UserRole.ELDERLY);
        }

        @Test
        @DisplayName("admin bulunamazsa exception fırlatır")
        void shouldThrowWhenAdminNotFound() {
            when(userRepository.findByEmail("unknown@test.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.createUser("unknown@test.com", createStudentRequest))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("User not found");
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN değilse exception fırlatır")
        void shouldThrowWhenNotAdmin() {
            institutionAdmin.setRole(User.UserRole.STUDENT);
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));

            assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("INSTITUTION_ADMIN");
        }

        @Test
        @DisplayName("email zaten varsa exception fırlatır")
        void shouldThrowWhenEmailExists() {
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.of(User.builder().build()));

            assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("already exists");
        }

        @Test
        @DisplayName("STUDENT için IBAN zorunludur")
        void shouldThrowWhenStudentWithoutIban() {
            createStudentRequest.setIban(null);
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("IBAN");
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN veya STUDENT dışı rol ile exception fırlatır")
        void shouldThrowWhenInvalidRole() {
            createStudentRequest.setRole(User.UserRole.INSTITUTION_ADMIN);
            // Rol kontrolü ilk yapılır, findByEmail çağrılmaz

            assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Only STUDENT or ELDERLY");
        }
    }

    @Nested
    @DisplayName("listUsersByInstitution")
    class ListUsersByInstitution {

        @Test
        @DisplayName("admin kurumunun kullanıcılarını listeler")
        void shouldListUsersForAdminInstitution() {
            User student = User.builder().id(UUID.randomUUID()).role(User.UserRole.STUDENT).build();
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByInstitutionIdOrderByCreatedAtDesc(institution.getId())).thenReturn(List.of(student));

            List<UserResponse> result = userService.listUsersByInstitution("admin@kurum.gov.tr", null);

            assertThat(result).hasSize(1);
            verify(userRepository).findByInstitutionIdOrderByCreatedAtDesc(institution.getId());
        }

        @Test
        @DisplayName("rol filtresi ile listeler")
        void shouldListUsersWithRoleFilter() {
            when(userRepository.findByEmail("admin@kurum.gov.tr")).thenReturn(Optional.of(institutionAdmin));
            when(userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(eq(institution.getId()), eq(User.UserRole.STUDENT)))
                    .thenReturn(List.of());

            List<UserResponse> result = userService.listUsersByInstitution("admin@kurum.gov.tr", User.UserRole.STUDENT);

            assertThat(result).isEmpty();
            verify(userRepository).findByInstitutionIdAndRoleOrderByCreatedAtDesc(institution.getId(), User.UserRole.STUDENT);
        }
    }
}
