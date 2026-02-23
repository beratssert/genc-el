package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.User;
import com.gencel.backend.service.AuthService;
import com.gencel.backend.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/user")
@RequiredArgsConstructor
@Tag(
        name = "User Management",
        description = "Kurum yöneticisinin kendi kurumuna bağlı öğrenci (STUDENT) ve yaşlı (ELDERLY) kullanıcıları yönetmesi için uç noktalar."
)
public class UserController {

    private final UserService userService;
    private final AuthService authService;

    @PostMapping("/login")
    @Operation(
            summary = "Kullanıcı girişi (STUDENT / ELDERLY)",
            description = "Öğrenci veya yaşlı kullanıcıların e-posta ve şifre ile sisteme giriş yapmasını sağlar. Başarılı girişte JWT token döner."
    )
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.userLogin(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(
            summary = "Kurum kullanıcısı oluştur",
            description = "Sadece INSTITUTION_ADMIN rolüne sahip kurum yöneticilerinin, kendi kurumuna bağlı STUDENT veya ELDERLY kullanıcı oluşturmasını sağlar."
    )
    public ResponseEntity<UserResponse> createUser(
            Authentication authentication,
            @Valid @RequestBody CreateUserRequest request
    ) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UserResponse userResponse = userService.createUser(email, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @GetMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(
            summary = "Kurum kullanıcılarını listele",
            description = "Sadece INSTITUTION_ADMIN tarafından çağrılabilir. Kurum yöneticisinin kendi kurumuna bağlı kullanıcıları listeler; isteğe bağlı rol filtresi ile (STUDENT, ELDERLY) filtreleme yapılabilir."
    )
    public ResponseEntity<List<UserResponse>> listUsers(
            Authentication authentication,
            @Parameter(description = "İsteğe bağlı rol filtresi (STUDENT, ELDERLY)")
            @RequestParam(required = false) User.UserRole role
    ) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        List<UserResponse> users = userService.listUsersByInstitution(email, role);
        return ResponseEntity.ok(users);
    }
}
