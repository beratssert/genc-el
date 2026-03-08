package com.gencel.backend.controller;

import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(
        name = "Admin Management",
        description = "Süper admin (SYSTEM_ADMIN) girişi. Süper admin sadece institution CRUD yapabilir; user yönetimi yapamaz."
)
public class AdminController {

    private final AuthService authService;

    @PostMapping("/login")
    @Operation(
            summary = "Süper admin girişi (SYSTEM_ADMIN)",
            description = "Süper adminin e-posta ve şifresiyle sisteme giriş yapmasını sağlar. Sadece SYSTEM_ADMIN rolüne sahip kullanıcılar giriş yapabilir. Başarılı girişte JWT token döner."
    )
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.superAdminLogin(request);
        return ResponseEntity.ok(response);
    }
}
