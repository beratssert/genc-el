package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.InstitutionRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("UserController Integration")
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private Institution institution;
    private User institutionAdmin;

    @BeforeEach
    void setUp() {
        institution = institutionRepository.save(Institution.builder()
                .name("Test Kurumu")
                .region("Ankara")
                .isActive(true)
                .build());
        institutionAdmin = userRepository.save(User.builder()
                .institution(institution)
                .role(User.UserRole.INSTITUTION_ADMIN)
                .email("admin-integration@test.com")
                .passwordHash(passwordEncoder.encode("Admin123!"))
                .firstName("Admin")
                .lastName("Test")
                .phoneNumber("0532 111 22 33")
                .isActive(true)
                .build());
    }

    @Nested
    @DisplayName("POST /api/v1/user/login")
    class UserLogin {

        @Test
        @DisplayName("geçerli STUDENT ile JWT döner")
        void shouldLoginStudent() throws Exception {
            userRepository.save(User.builder()
                    .institution(institution)
                    .role(User.UserRole.STUDENT)
                    .email("student-integration@test.com")
                    .passwordHash(passwordEncoder.encode("Student123!"))
                    .firstName("Ahmet")
                    .lastName("Yılmaz")
                    .phoneNumber("0532 999 88 77")
                    .iban("TR00 0000 0000 0000 0000 0000 00")
                    .isActive(true)
                    .build());

            LoginRequest request = LoginRequest.builder()
                    .email("student-integration@test.com")
                    .password("Student123!")
                    .build();

            mockMvc.perform(post("/api/v1/user/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.token").exists())
                    .andExpect(jsonPath("$.email").value("student-integration@test.com"))
                    .andExpect(jsonPath("$.role").value("STUDENT"));
        }
    }

    @Nested
    @DisplayName("POST /api/v1/user (Create - INSTITUTION_ADMIN)")
    class CreateUser {

        @Test
        @DisplayName("INSTITUTION_ADMIN ile geçerli STUDENT oluşturur")
        void shouldCreateStudentWhenAdminAuthenticated() throws Exception {
            CreateUserRequest request = CreateUserRequest.builder()
                    .role(User.UserRole.STUDENT)
                    .firstName("Yeni")
                    .lastName("Öğrenci")
                    .email("yeni.ogrenci@test.com")
                    .phoneNumber("0533 444 55 66")
                    .password("YeniOgr123!")
                    .iban("TR11 1111 1111 1111 1111 1111 11")
                    .build();

            mockMvc.perform(post("/api/v1/user")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").exists())
                    .andExpect(jsonPath("$.email").value("yeni.ogrenci@test.com"))
                    .andExpect(jsonPath("$.role").value("STUDENT"))
                    .andExpect(jsonPath("$.firstName").value("Yeni"))
                    .andExpect(jsonPath("$.lastName").value("Öğrenci"));
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN ile geçerli ELDERLY oluşturur")
        void shouldCreateElderlyWhenAdminAuthenticated() throws Exception {
            CreateUserRequest request = CreateUserRequest.builder()
                    .role(User.UserRole.ELDERLY)
                    .firstName("Yaşlı")
                    .lastName("Birey")
                    .email("yasli@test.com")
                    .phoneNumber("0533 777 88 99")
                    .password("Yasli123!")
                    .build();

            mockMvc.perform(post("/api/v1/user")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.role").value("ELDERLY"));
        }

        @Test
        @DisplayName("yetkisiz (anonymous) ile 401/403")
        void shouldRejectWhenUnauthorized() throws Exception {
            CreateUserRequest request = CreateUserRequest.builder()
                    .role(User.UserRole.STUDENT)
                    .firstName("X")
                    .lastName("Y")
                    .email("x@y.com")
                    .phoneNumber("0555")
                    .password("Pass123!")
                    .iban("TR00 0000 0000 0000 0000 0000 00")
                    .build();

            mockMvc.perform(post("/api/v1/user")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden()); // 403 - yetkisiz (anonymous)
        }

        @Test
        @DisplayName("validation hatası (şifre zayıf) ile 400")
        void shouldReturn400WhenValidationFails() throws Exception {
            CreateUserRequest request = CreateUserRequest.builder()
                    .role(User.UserRole.STUDENT)
                    .firstName("X")
                    .lastName("Y")
                    .email("x@y.com")
                    .phoneNumber("0555")
                    .password("short") // 8 kar, büyük/küçük/rakam gerekli
                    .iban("TR00 0000 0000 0000 0000 0000 00")
                    .build();

            mockMvc.perform(post("/api/v1/user")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/user (List)")
    class ListUsers {

        @Test
        @DisplayName("INSTITUTION_ADMIN kurumunun kullanıcılarını listeler")
        void shouldListUsersForAdmin() throws Exception {
            userRepository.save(User.builder()
                    .institution(institution)
                    .role(User.UserRole.STUDENT)
                    .email("list.student@test.com")
                    .passwordHash("x")
                    .firstName("List")
                    .lastName("Student")
                    .phoneNumber("0555")
                    .iban("TR00")
                    .isActive(true)
                    .build());

            mockMvc.perform(get("/api/v1/user")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN")))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$[?(@.email=='list.student@test.com')]").exists());
        }

        @Test
        @DisplayName("rol filtresi ile listeler")
        void shouldListWithRoleFilter() throws Exception {
            mockMvc.perform(get("/api/v1/user")
                            .param("role", "STUDENT")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN")))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }
    }
}
