package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.ChangePasswordRequest;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.InstitutionRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("AuthController Integration")
class AuthControllerIntegrationTest {

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

  private User studentUser;

  @BeforeEach
  void setUp() {
    Institution institution = institutionRepository.save(Institution.builder()
        .name("Test Institution")
        .region("Ankara")
        .isActive(true)
        .build());

    studentUser = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .email("auth-student@test.com")
        .passwordHash(passwordEncoder.encode("Student123!"))
        .firstName("Auth")
        .lastName("Student")
        .isActive(true)
        .build());
  }

  @Test
  @DisplayName("POST /api/v1/auth/refresh-token yeni token döner")
  void shouldRefreshToken() throws Exception {
    mockMvc.perform(post("/api/v1/auth/refresh-token")
        .with(user(studentUser.getEmail()).roles("STUDENT"))
        .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token").exists());
  }

  @Test
  @DisplayName("POST /api/v1/auth/change-password şifreyi değiştirir")
  void shouldChangePassword() throws Exception {
    ChangePasswordRequest request = ChangePasswordRequest.builder()
        .currentPassword("Student123!")
        .newPassword("Updated123A")
        .build();

    mockMvc.perform(post("/api/v1/auth/change-password")
        .with(user(studentUser.getEmail()).roles("STUDENT"))
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isNoContent());
  }

  @Test
  @DisplayName("POST /api/v1/auth/change-password yanlış mevcut şifrede 401 döner")
  void shouldReturnUnauthorizedWhenCurrentPasswordIsWrong() throws Exception {
    ChangePasswordRequest request = ChangePasswordRequest.builder()
        .currentPassword("WrongPass123")
        .newPassword("Updated123A")
        .build();

    mockMvc.perform(post("/api/v1/auth/change-password")
        .with(user(studentUser.getEmail()).roles("STUDENT"))
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error").exists());
  }
}
