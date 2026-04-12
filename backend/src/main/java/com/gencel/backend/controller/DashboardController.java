package com.gencel.backend.controller;

import com.gencel.backend.dto.DashboardStatsResponse;
import com.gencel.backend.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Öğrenci ve kurum yöneticisi için özet istatistik uç noktaları")
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/stats")
    @Operation(
            summary = "Dashboard istatistikleri",
            description = "Giriş yapmış kullanıcının rolüne göre (STUDENT veya INSTITUTION_ADMIN) ilgili istatistikleri döner."
    )
    public ResponseEntity<DashboardStatsResponse> getStats(
            @Parameter(hidden = true) Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        DashboardStatsResponse response = dashboardService.getDashboardStats(email);
        return ResponseEntity.ok(response);
    }
}

