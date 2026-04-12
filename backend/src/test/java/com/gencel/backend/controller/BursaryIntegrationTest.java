package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.BursaryPaymentRequest;
import com.gencel.backend.dto.CalculateBursaryRequest;
import com.gencel.backend.entity.BursaryHistory;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.BursaryHistoryRepository;
import com.gencel.backend.repository.InstitutionRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class BursaryIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BursaryHistoryRepository bursaryHistoryRepository;

    private User student;
    private User admin;
    private Institution institution;

    @BeforeEach
    void setUp() {
        bursaryHistoryRepository.deleteAll();
        userRepository.deleteAll();
        institutionRepository.deleteAll();

        institution = new Institution();
        institution.setName("Test Institution");
        institution.setContactInfo("12345");
        institution.setRegion("Test Region");
        institution.setIsActive(true);
        institution = institutionRepository.save(institution);

        admin = new User();
        admin.setEmail("admin@bursary.test.com");
        admin.setRole(User.UserRole.INSTITUTION_ADMIN);
        admin.setInstitution(institution);
        admin.setPasswordHash("hashed_password");
        admin = userRepository.save(admin);

        student = new User();
        student.setEmail("student@bursary.test.com");
        student.setRole(User.UserRole.STUDENT);
        student.setInstitution(institution);
        student.setPasswordHash("hashed_password");
        student = userRepository.save(student);
    }

    @AfterEach
    void tearDown() {
        bursaryHistoryRepository.deleteAll();
        userRepository.deleteAll();
        institutionRepository.deleteAll();
    }

    @Test
    @WithMockUser(username = "student@bursary.test.com", roles = "STUDENT")
    void getMyBursaries_Success() throws Exception {
        BursaryHistory record = BursaryHistory.builder()
                .student(student)
                .year(2024)
                .month(2)
                .calculatedAmount(5000.0)
                .completedTaskCount(5)
                .isPaid(false)
                .build();
        bursaryHistoryRepository.save(record);

        mockMvc.perform(get("/api/v1/bursaries/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.size()").value(1))
                .andExpect(jsonPath("$[0].calculatedAmount").value(5000.0))
                .andExpect(jsonPath("$[0].isPaid").value(false));
    }

    @Test
    @WithMockUser(username = "admin@bursary.test.com", roles = "INSTITUTION_ADMIN")
    void getInstitutionBursaries_Success() throws Exception {
        BursaryHistory record = BursaryHistory.builder()
                .student(student)
                .year(2024)
                .month(2)
                .calculatedAmount(10000.0)
                .completedTaskCount(12)
                .isPaid(false)
                .build();
        bursaryHistoryRepository.save(record);

        mockMvc.perform(get("/api/v1/bursaries/institution")
                .param("year", "2024")
                .param("month", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.size()").value(1))
                .andExpect(jsonPath("$[0].studentEmail").doesNotExist()) // Optional based on DTO
                .andExpect(jsonPath("$[0].calculatedAmount").value(10000.0));
    }

    @Test
    @WithMockUser(username = "admin@bursary.test.com", roles = "INSTITUTION_ADMIN")
    void calculateBursariesManually_Success() throws Exception {
        CalculateBursaryRequest request = new CalculateBursaryRequest();
        request.setYear(2024);
        request.setMonth(2);

        mockMvc.perform(post("/api/v1/bursaries/calculate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Bursary calculations completed successfully for 2/2024"));
    }

    @Test
    @WithMockUser(username = "admin@bursary.test.com", roles = "INSTITUTION_ADMIN")
    void calculateBursariesManually_InvalidMonth_BadRequest() throws Exception {
        CalculateBursaryRequest request = new CalculateBursaryRequest();
        request.setYear(2024);
        request.setMonth(13); // invalid month

        mockMvc.perform(post("/api/v1/bursaries/calculate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "admin@bursary.test.com", roles = "INSTITUTION_ADMIN")
    void markAsPaid_Success() throws Exception {
        BursaryHistory record = BursaryHistory.builder()
                .student(student)
                .year(2024)
                .month(2)
                .calculatedAmount(10000.0)
                .completedTaskCount(10)
                .isPaid(false)
                .build();
        record = bursaryHistoryRepository.save(record);

        BursaryPaymentRequest request = new BursaryPaymentRequest("TRX-999");

        mockMvc.perform(put("/api/v1/bursaries/" + record.getId() + "/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isPaid").value(true))
                .andExpect(jsonPath("$.transactionReference").value("TRX-999"))
                .andExpect(jsonPath("$.paymentDate").exists());
    }

    @Test
    @WithMockUser(username = "student@bursary.test.com", roles = "STUDENT")
    void calculateBursariesManually_Forbidden() throws Exception {
        CalculateBursaryRequest request = new CalculateBursaryRequest();
        request.setYear(2024);
        request.setMonth(2);

        // Students shouldn't trigger calculation
        mockMvc.perform(post("/api/v1/bursaries/calculate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "admin@bursary.test.com", roles = "INSTITUTION_ADMIN")
    void getMyBursaries_ForbiddenForAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/bursaries/me"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "student@bursary.test.com", roles = "STUDENT")
    void getInstitutionBursaries_ForbiddenForStudent() throws Exception {
        mockMvc.perform(get("/api/v1/bursaries/institution")
                .param("year", "2024")
                .param("month", "2"))
                .andExpect(status().isForbidden());
    }
}
