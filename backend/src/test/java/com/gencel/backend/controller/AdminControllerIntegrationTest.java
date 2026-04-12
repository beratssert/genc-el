package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("AdminController Integration")
class AdminControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Nested
    @DisplayName("POST /api/v1/admin/login")
    class AdminLogin {

        @Test
        @DisplayName("geçerli SYSTEM_ADMIN ile JWT döner")
        void shouldLoginSuperAdmin() throws Exception {
            User superAdmin = userRepository.save(User.builder()
                    .role(User.UserRole.SYSTEM_ADMIN)
                    .email("superadmin@test.com")
                    .passwordHash(passwordEncoder.encode("Super123!"))
                    .firstName("Super")
                    .lastName("Admin")
                    .phoneNumber("0555 000 00 00")
                    .isActive(true)
                    .build());

            LoginRequest request = LoginRequest.builder()
                    .email(superAdmin.getEmail())
                    .password("Super123!")
                    .build();

            mockMvc.perform(post("/api/v1/admin/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.token").exists())
                    .andExpect(jsonPath("$.email").value(superAdmin.getEmail()))
                    .andExpect(jsonPath("$.role").value("SYSTEM_ADMIN"));
        }

        @Test
        @DisplayName("yanlış şifre ile 401 Unauthorized döner")
        void shouldReturn401WhenWrongPassword() throws Exception {
            User superAdmin = userRepository.save(User.builder()
                    .role(User.UserRole.SYSTEM_ADMIN)
                    .email("superadmin@test.com")
                    .passwordHash(passwordEncoder.encode("CorrectPass123!"))
                    .firstName("Super")
                    .lastName("Admin")
                    .phoneNumber("0555 000 00 00")
                    .isActive(true)
                    .build());

            LoginRequest request = LoginRequest.builder()
                    .email(superAdmin.getEmail())
                    .password("WrongPass!")
                    .build();

            mockMvc.perform(post("/api/v1/admin/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN /admin/login ile giriş yapamaz (401)")
        void institutionAdminCannotLoginViaAdminEndpoint() throws Exception {
            User institutionAdmin = userRepository.save(User.builder()
                    .role(User.UserRole.INSTITUTION_ADMIN)
                    .email("admin@kurum.test")
                    .passwordHash(passwordEncoder.encode("Admin123!"))
                    .firstName("Inst")
                    .lastName("Admin")
                    .phoneNumber("0555 111 11 11")
                    .isActive(true)
                    .build());

            LoginRequest request = LoginRequest.builder()
                    .email(institutionAdmin.getEmail())
                    .password("Admin123!")
                    .build();

            mockMvc.perform(post("/api/v1/admin/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }
    }
}

