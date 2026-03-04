package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.service.AuthService;
import com.gencel.backend.service.InstitutionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/institution")
@RequiredArgsConstructor
@Tag(
        name = "Institution Management",
        description = "Kurum yönetimi ve kurum yöneticisi (INSTITUTION_ADMIN) ile ilgili uç noktalar."
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
    // @PreAuthorize("hasRole('SYSTEM_ADMIN')") // İleride sadece sistem yöneticilerine açılabilir.
    @Operation(
            summary = "Yeni kurum oluştur",
            description = "Yeni bir kurum kaydı oluşturur. Geçici olarak herkese açık; ileride sadece sistem yöneticilerine sınırlandırılabilir."
    )
    public ResponseEntity<InstitutionResponse> createInstitution(@Valid @RequestBody CreateInstitutionRequest request) {
        InstitutionResponse response = institutionService.createInstitution(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @Operation(
            summary = "Tüm kurumları listele",
            description = "Sistemde kayıtlı tüm kurumları listeler."
    )
    public ResponseEntity<List<InstitutionResponse>> getAllInstitutions() {
        List<InstitutionResponse> responses = institutionService.getAllInstitutions();
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/{id}")
    @Operation(
            summary = "ID ile kurum getir",
            description = "Verilen kurum ID'sine göre kurum detaylarını döner."
    )
    public ResponseEntity<InstitutionResponse> getInstitutionById(@PathVariable UUID id) {
        InstitutionResponse response = institutionService.getInstitutionById(id);
        return ResponseEntity.ok(response);
    }
}
