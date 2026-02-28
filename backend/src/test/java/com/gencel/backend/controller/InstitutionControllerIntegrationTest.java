package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.CreateInstitutionRequest;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("InstitutionController Integration")
class InstitutionControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        institutionRepository.deleteAll();
        userRepository.deleteAll(); // Native query ile soft-deleted dahil temizlenmiyor olabilir; test DB create-drop olduğu için genelde sorun olmaz
    }

    @Nested
    @DisplayName("POST /api/v1/institution (Create)")
    class CreateInstitution {

        @Test
        @DisplayName("geçerli body ile 201 CREATED döner")
        void shouldCreateInstitution() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Yeni Kurum")
                    .region("İstanbul/Kadıköy")
                    .contactInfo("0216 555 00 00")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").exists())
                    .andExpect(jsonPath("$.name").value("Yeni Kurum"))
                    .andExpect(jsonPath("$.region").value("İstanbul/Kadıköy"))
                    .andExpect(jsonPath("$.contactInfo").value("0216 555 00 00"))
                    .andExpect(jsonPath("$.isActive").value(true));
        }

        @Test
        @DisplayName("name boş ise 400 Bad Request")
        void shouldReturn400WhenNameBlank() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("")
                    .region("Ankara")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("region boş ise 400 Bad Request")
        void shouldReturn400WhenRegionBlank() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Kurum")
                    .region("")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/institution (List)")
    class GetAllInstitutions {

        @Test
        @DisplayName("tüm kurumları listeler")
        void shouldListAllInstitutions() throws Exception {
            institutionRepository.save(Institution.builder().name("K1").region("R1").isActive(true).build());
            institutionRepository.save(Institution.builder().name("K2").region("R2").isActive(true).build());

            mockMvc.perform(get("/api/v1/institution"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$.length()").value(2));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/institution/{id}")
    class GetInstitutionById {

        @Test
        @DisplayName("geçerli ID ile kurum döner")
        void shouldReturnInstitutionById() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Test Kurumu")
                    .region("Ankara")
                    .isActive(true)
                    .build());

            mockMvc.perform(get("/api/v1/institution/{id}", inst.getId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.id").value(inst.getId().toString()))
                    .andExpect(jsonPath("$.name").value("Test Kurumu"));
        }

        @Test
        @DisplayName("mevcut olmayan ID ile 400 döner")
        void shouldReturn400WhenNotFound() throws Exception {
            mockMvc.perform(get("/api/v1/institution/{id}", java.util.UUID.randomUUID()))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/institution/login")
    class InstitutionLogin {

        @Test
        @DisplayName("geçerli admin ile JWT döner")
        void shouldLoginAndReturnJwt() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Kurum").region("R").isActive(true).build());
            User admin = User.builder()
                    .institution(inst)
                    .role(User.UserRole.INSTITUTION_ADMIN)
                    .email("admin@kurum.gov.tr")
                    .passwordHash(passwordEncoder.encode("Admin123!"))
                    .firstName("Admin")
                    .lastName("Test")
                    .phoneNumber("555")
                    .isActive(true)
                    .build();
            userRepository.save(admin);

            LoginRequest request = LoginRequest.builder()
                    .email("admin@kurum.gov.tr")
                    .password("Admin123!")
                    .build();

            mockMvc.perform(post("/api/v1/institution/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.token").exists())
                    .andExpect(jsonPath("$.email").value("admin@kurum.gov.tr"))
                    .andExpect(jsonPath("$.role").value("INSTITUTION_ADMIN"));
        }

        @Test
        @DisplayName("yanlış şifre ile 401")
        void shouldReturn401WhenWrongPassword() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder().name("K").region("R").isActive(true).build());
            User admin = User.builder()
                    .institution(inst)
                    .role(User.UserRole.INSTITUTION_ADMIN)
                    .email("a@b.com")
                    .passwordHash(passwordEncoder.encode("correct"))
                    .firstName("A")
                    .lastName("B")
                    .phoneNumber("555")
                    .isActive(true)
                    .build();
            userRepository.save(admin);

            LoginRequest request = LoginRequest.builder().email("a@b.com").password("wrong").build();

            mockMvc.perform(post("/api/v1/institution/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }
    }
}
