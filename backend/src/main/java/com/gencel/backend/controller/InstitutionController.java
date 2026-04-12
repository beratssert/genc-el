package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.service.AuthService;
import com.gencel.backend.service.InstitutionService;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/institution")
@RequiredArgsConstructor
@Tag(
        name = "Institution Management",
        description = "SYSTEM_ADMIN: tam institution CRUD. INSTITUTION_ADMIN: login, kendi kurumunu güncelle/sil (PUT/DELETE /me)."
)
public class InstitutionController {

    private final InstitutionService institutionService;
    private final AuthService authService;

    @PostMapping("/login")
    @Operation(
            summary = "Kurum yöneticisi girişi (INSTITUTION_ADMIN)",
            description = "Kurum yöneticisinin (INSTITUTION_ADMIN) e-posta ve şifresiyle sisteme giriş yapmasını sağlar. Başarılı girişte JWT token döner."
    )
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.institutionLogin(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    @Operation(
            summary = "Yeni kurum oluştur",
            description = "Yeni bir kurum kaydı oluşturur. Sadece SYSTEM_ADMIN (süper admin) tarafından çağrılabilir."
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<InstitutionResponse> createInstitution(@Valid @RequestBody CreateInstitutionRequest request) {
        InstitutionResponse response = institutionService.createInstitution(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @Operation(
            summary = "Tüm kurumları listele",
            description = "Sistemde kayıtlı tüm kurumları listeler. Sadece SYSTEM_ADMIN (süper admin) tarafından çağrılabilir."
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<List<InstitutionResponse>> getAllInstitutions() {
        List<InstitutionResponse> responses = institutionService.getAllInstitutions();
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/{id}")
    @Operation(
            summary = "ID ile kurum getir",
            description = "Verilen kurum ID'sine göre kurum detaylarını döner. Sadece SYSTEM_ADMIN (süper admin) tarafından çağrılabilir."
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<InstitutionResponse> getInstitutionById(@PathVariable UUID id) {
        InstitutionResponse response = institutionService.getInstitutionById(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me")
    @Operation(
            summary = "Kurumumun bilgilerini güncelle",
            description = "Giriş yapmış kurum yöneticisinin (INSTITUTION_ADMIN) kendi kurumunun ad, bölge ve iletişim bilgilerini günceller."
    )
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    public ResponseEntity<InstitutionResponse> updateMyInstitution(
            @Parameter(hidden = true) Authentication authentication,
            @Valid @RequestBody CreateInstitutionRequest request
    ) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        InstitutionResponse response = institutionService.updateMyInstitution(email, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/me")
    @Operation(
            summary = "Kurumumu sil (soft-delete)",
            description = "Giriş yapmış kurum yöneticisinin (INSTITUTION_ADMIN) kendi kurum kaydını soft-delete etmesini sağlar (is_active=false)."
    )
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    public ResponseEntity<Void> deleteMyInstitution(
            @Parameter(hidden = true) Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        institutionService.deleteMyInstitution(email);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}")
    @Operation(
            summary = "Kurumu güncelle",
            description = "Var olan bir kurum kaydını günceller. Sadece SYSTEM_ADMIN (süper admin) tarafından çağrılabilir."
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<InstitutionResponse> updateInstitution(
            @PathVariable UUID id,
            @Valid @RequestBody CreateInstitutionRequest request
    ) {
        InstitutionResponse response = institutionService.updateInstitution(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(
            summary = "Kurumu sil (soft-delete)",
            description = "Kurum kaydını soft-delete eder (is_active=false). Sadece SYSTEM_ADMIN (süper admin) tarafından çağrılabilir."
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<Void> deleteInstitution(@PathVariable UUID id) {
        institutionService.deleteInstitution(id);
        return ResponseEntity.noContent().build();
    }
}
