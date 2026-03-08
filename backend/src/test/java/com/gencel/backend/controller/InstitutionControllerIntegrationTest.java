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

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
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

    private Institution defaultInstitution;
    private User institutionAdmin;
    private User superAdmin;

    @BeforeEach
    void setUp() {
        institutionRepository.deleteAll();
        userRepository.deleteAll(); // Native query ile soft-deleted dahil temizlenmiyor olabilir; test DB create-drop olduğu için genelde sorun olmaz

        defaultInstitution = institutionRepository.save(Institution.builder()
                .name("Default Kurum")
                .region("Ankara")
                .contactInfo("0312 000 00 00")
                .isActive(true)
                .build());

        institutionAdmin = userRepository.save(User.builder()
                .institution(defaultInstitution)
                .role(User.UserRole.INSTITUTION_ADMIN)
                .email("institution.admin@test.com")
                .passwordHash(passwordEncoder.encode("Admin123!"))
                .firstName("Inst")
                .lastName("Admin")
                .phoneNumber("0555 000 00 00")
                .isActive(true)
                .build());

        superAdmin = userRepository.save(User.builder()
                .institution(null)
                .role(User.UserRole.SYSTEM_ADMIN)
                .email("super.admin@test.com")
                .passwordHash(passwordEncoder.encode("Super123!"))
                .firstName("Super")
                .lastName("Admin")
                .phoneNumber("0555 111 11 11")
                .isActive(true)
                .build());
    }

    @Nested
    @DisplayName("POST /api/v1/institution (Create)")
    class CreateInstitution {

        @Test
        @DisplayName("SYSTEM_ADMIN ile geçerli body 201 CREATED döner")
        void shouldCreateInstitution() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Yeni Kurum")
                    .region("İstanbul/Kadıköy")
                    .contactInfo("0216 555 00 00")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN"))
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
        @DisplayName("INSTITUTION_ADMIN ile 403 Forbidden döner")
        void shouldForbidCreateForInstitutionAdmin() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Yeni Kurum")
                    .region("İstanbul/Kadıköy")
                    .contactInfo("0216 555 00 00")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("name boş ise 400 Bad Request")
        void shouldReturn400WhenNameBlank() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("")
                    .region("Ankara")
                    .build();

            mockMvc.perform(post("/api/v1/institution")
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN"))
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
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/institution (List)")
    class GetAllInstitutions {

        @Test
        @DisplayName("SYSTEM_ADMIN tüm aktif kurumları listeleyebilir")
        void shouldListAllInstitutions() throws Exception {
            institutionRepository.save(Institution.builder().name("K1").region("R1").isActive(true).build());
            institutionRepository.save(Institution.builder().name("K2").region("R2").isActive(true).build());

            mockMvc.perform(get("/api/v1/institution")
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN")))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    // setUp'ta oluşturulan defaultInstitution + burada eklenen 2 kurum = 3
                    .andExpect(jsonPath("$.length()").value(3));
        }

        @Test
        @DisplayName("anonymous istek 403 Forbidden döner")
        void shouldForbidListForAnonymous() throws Exception {
            mockMvc.perform(get("/api/v1/institution"))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/institution/{id}")
    class GetInstitutionById {

        @Test
        @DisplayName("SYSTEM_ADMIN geçerli ID ile kurum döner")
        void shouldReturnInstitutionById() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Test Kurumu")
                    .region("Ankara")
                    .isActive(true)
                    .build());

            mockMvc.perform(get("/api/v1/institution/{id}", inst.getId())
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN")))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.id").value(inst.getId().toString()))
                    .andExpect(jsonPath("$.name").value("Test Kurumu"));
        }

        @Test
        @DisplayName("mevcut olmayan ID ile 400 döner")
        void shouldReturn400WhenNotFound() throws Exception {
            mockMvc.perform(get("/api/v1/institution/{id}", java.util.UUID.randomUUID())
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN")))
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

    @Nested
    @DisplayName("PUT /api/v1/institution/me (Institution admin self update)")
    class UpdateMyInstitution {

        @Test
        @DisplayName("INSTITUTION_ADMIN kendi kurum bilgilerini günceller")
        void institutionAdminCanUpdateOwnInstitution() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Güncellenmiş Kurum")
                    .region("İstanbul")
                    .contactInfo("0212 000 00 00")
                    .build();

            mockMvc.perform(put("/api/v1/institution/me")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.name").value("Güncellenmiş Kurum"))
                    .andExpect(jsonPath("$.region").value("İstanbul"))
                    .andExpect(jsonPath("$.contactInfo").value("0212 000 00 00"));
        }

        @Test
        @DisplayName("SYSTEM_ADMIN /me endpoint'ini kullanamaz (403)")
        void superAdminCannotUseMeEndpoint() throws Exception {
            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Deneme")
                    .region("Deneme Bölge")
                    .contactInfo("0000")
                    .build();

            mockMvc.perform(put("/api/v1/institution/me")
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("DELETE /api/v1/institution/me (Institution admin self delete)")
    class DeleteMyInstitution {

        @Test
        @DisplayName("INSTITUTION_ADMIN kendi kurumunu soft-delete yapabilir")
        void institutionAdminCanDeleteOwnInstitution() throws Exception {
            mockMvc.perform(delete("/api/v1/institution/me")
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN")))
                    .andExpect(status().isNoContent());

            org.assertj.core.api.Assertions.assertThat(
                    institutionRepository.findById(defaultInstitution.getId())
            ).isEmpty();
        }

        @Test
        @DisplayName("SYSTEM_ADMIN /me delete endpoint'ini kullanamaz (403)")
        void superAdminCannotDeleteViaMeEndpoint() throws Exception {
            mockMvc.perform(delete("/api/v1/institution/me")
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN")))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("PUT & DELETE /api/v1/institution/{id} (Super admin CRUD)")
    class UpdateAndDeleteInstitutionById {

        @Test
        @DisplayName("SYSTEM_ADMIN kurumu güncelleyebilir")
        void superAdminCanUpdateInstitutionById() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Eski Kurum")
                    .region("Eski Bölge")
                    .contactInfo("000")
                    .isActive(true)
                    .build());

            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Yeni Kurum Adı")
                    .region("Yeni Bölge")
                    .contactInfo("111")
                    .build();

            mockMvc.perform(put("/api/v1/institution/{id}", inst.getId())
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.name").value("Yeni Kurum Adı"))
                    .andExpect(jsonPath("$.region").value("Yeni Bölge"))
                    .andExpect(jsonPath("$.contactInfo").value("111"));
        }

        @Test
        @DisplayName("SYSTEM_ADMIN kurumu soft-delete yapabilir")
        void superAdminCanSoftDeleteInstitution() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Silinecek Kurum")
                    .region("Bölge")
                    .contactInfo("000")
                    .isActive(true)
                    .build());

            mockMvc.perform(delete("/api/v1/institution/{id}", inst.getId())
                            .with(user(superAdmin.getEmail()).roles("SYSTEM_ADMIN")))
                    .andExpect(status().isNoContent());

            // @SQLRestriction nedeniyle soft-delete sonrası findById, aktif kayıtı döndürmemeli
            org.assertj.core.api.Assertions.assertThat(institutionRepository.findById(inst.getId())).isEmpty();
        }

        @Test
        @DisplayName("INSTITUTION_ADMIN /{id} update/delete yapamaz (403)")
        void institutionAdminCannotUpdateOrDeleteById() throws Exception {
            Institution inst = institutionRepository.save(Institution.builder()
                    .name("Kurum")
                    .region("Bölge")
                    .contactInfo("000")
                    .isActive(true)
                    .build());

            CreateInstitutionRequest request = CreateInstitutionRequest.builder()
                    .name("Deneme")
                    .region("Deneme")
                    .contactInfo("111")
                    .build();

            mockMvc.perform(put("/api/v1/institution/{id}", inst.getId())
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());

            mockMvc.perform(delete("/api/v1/institution/{id}", inst.getId())
                            .with(user(institutionAdmin.getEmail()).roles("INSTITUTION_ADMIN")))
                    .andExpect(status().isForbidden());
        }
    }
}
