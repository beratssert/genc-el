package com.gencel.backend.controller;
import com.gencel.backend.dto.DashboardStatsResponse;
import com.gencel.backend.service.DashboardService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("DashboardController Integration")
class DashboardIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DashboardService dashboardService;

    @Nested
    @DisplayName("GET /api/v1/dashboard/stats")
    class GetStats {

        @Test
        @DisplayName("öğrenci için istatistikleri döner")
        void shouldReturnStatsForStudent() throws Exception {
            DashboardStatsResponse response = DashboardStatsResponse.builder()
                    .totalCompletedTasks(10L)
                    .estimatedCurrentMonthBursary(10000.0)
                    .build();

            when(dashboardService.getDashboardStats(eq("student@test.com"))).thenReturn(response);

            mockMvc.perform(get("/api/v1/dashboard/stats")
                            .with(user("student@test.com").roles("STUDENT"))
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.totalCompletedTasks").value(10))
                    .andExpect(jsonPath("$.estimatedCurrentMonthBursary").value(10000.0));
        }

        @Test
        @DisplayName("anonymous istek için 401 döner")
        void shouldReturnUnauthorizedForAnonymous() throws Exception {
            mockMvc.perform(get("/api/v1/dashboard/stats"))
                    .andExpect(status().isForbidden());
        }
    }
}

