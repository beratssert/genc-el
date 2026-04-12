package com.gencel.backend.controller;

import com.gencel.backend.dto.BursaryPaymentRequest;
import com.gencel.backend.dto.BursaryResponse;
import com.gencel.backend.dto.CalculateBursaryRequest;
import com.gencel.backend.service.BursaryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/bursaries")
@RequiredArgsConstructor
@Tag(name = "Bursary Management", description = "Öğrenci burs hesaplama ve listeleme API'leri")
public class BursaryController {

    private final BursaryService bursaryService;

    @GetMapping("/me")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Kendi burs geçmişimi gör", description = "Giriş yapmış öğrencinin kendi burs ödemelerini listeler.")
    public ResponseEntity<List<BursaryResponse>> getMyBursaries(
            @Parameter(hidden = true) Authentication authentication) {
        return ResponseEntity.ok(bursaryService.getStudentBursaryHistory(authentication.getName()));
    }

    @GetMapping("/institution")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kuruma ait öğrencilerin burslarını listele", description = "Kurum yöneticisi, kendi kurumundaki öğrencilerin belirli bir aydaki burs hak edişlerini görüntüler.")
    public ResponseEntity<List<BursaryResponse>> getInstitutionBursaries(
            @RequestParam int year,
            @RequestParam int month,
            @Parameter(hidden = true) Authentication authentication) {
        return ResponseEntity.ok(bursaryService.getBursariesForInstitution(authentication.getName(), year, month));
    }

    @PostMapping("/calculate")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Manuel Burs Hesaplamasını Tetikle", description = "Belirtilen ay ve yıl için kurumdaki öğrencilerin tamamladıkları görevleri sayarak burs hak edişlerini hesaplar. Eğer öğrenci 10 görev yaparsa tam burs (10.000 TL), daha az yaparsa orantılı miktar alır.")
    public ResponseEntity<Map<String, String>> calculateBursariesManually(
            @Valid @RequestBody CalculateBursaryRequest request) {
        bursaryService.calculateBursariesForMonth(request.getYear(), request.getMonth());
        return ResponseEntity.ok(Map.of("message",
                "Bursary calculations completed successfully for " + request.getMonth() + "/" + request.getYear()));
    }

    @PutMapping("/{id}/pay")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Bursu Ödendi Olarak İşaretle", description = "Kurum yöneticisinin, bir öğrenciye ödemeyi yaptıktan sonra kaydı güncelleyip referans/dekont girmesini sağlar.")
    public ResponseEntity<BursaryResponse> markAsPaid(
            @PathVariable UUID id,
            @RequestBody(required = false) BursaryPaymentRequest request,
            @Parameter(hidden = true) Authentication authentication) {
        return ResponseEntity.ok(bursaryService.markBursaryAsPaid(id, authentication.getName(), request));
    }
}
