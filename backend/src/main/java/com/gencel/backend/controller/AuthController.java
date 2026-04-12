package com.gencel.backend.controller;

import com.gencel.backend.dto.ChangePasswordRequest;
import com.gencel.backend.dto.RefreshTokenResponse;
import com.gencel.backend.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Auth", description = "Token yenileme ve şifre değiştirme işlemleri")
public class AuthController {

  private final AuthService authService;

  @PostMapping("/refresh-token")
  @Operation(summary = "Token yenile", description = "Giriş yapmış kullanıcı için yeni JWT üretir.")
  public ResponseEntity<RefreshTokenResponse> refreshToken(
      @Parameter(hidden = true) Authentication authentication) {
    String email = authentication != null ? authentication.getName() : null;
    if (email == null || email.isBlank()) {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }

    return ResponseEntity.ok(authService.refreshToken(email));
  }

  @PostMapping("/change-password")
  @Operation(summary = "Şifre değiştir", description = "Giriş yapmış kullanıcının mevcut şifresini doğrulayıp yeni şifreye günceller.")
  public ResponseEntity<Void> changePassword(
      @Parameter(hidden = true) Authentication authentication,
      @Valid @RequestBody ChangePasswordRequest request) {
    String email = authentication != null ? authentication.getName() : null;
    if (email == null || email.isBlank()) {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }

    authService.changePassword(email, request);
    return ResponseEntity.noContent().build();
  }
}
