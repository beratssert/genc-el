package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.UpdateFcmTokenRequest;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.dto.UpdateLocationRequest;
import com.gencel.backend.dto.UpdateUserProfileRequest;
import com.gencel.backend.dto.UserPageResponse;
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
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/user")
@RequiredArgsConstructor
@Tag(name = "User Management", description = "Kurum yöneticisinin kendi kurumuna bağlı öğrenci (STUDENT) ve yaşlı (ELDERLY) kullanıcıları yönetmesi için uç noktalar.")
public class UserController {

    private final UserService userService;
    private final AuthService authService;

    @PostMapping("/login")
    @Operation(summary = "Kullanıcı girişi (STUDENT / ELDERLY)", description = "Öğrenci veya yaşlı kullanıcıların e-posta ve şifre ile sisteme giriş yapmasını sağlar. Başarılı girişte JWT token döner.")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.userLogin(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    @Operation(summary = "Benim profilim", description = "Giriş yapmış kullanıcının (STUDENT, ELDERLY veya INSTITUTION_ADMIN) kendi profil bilgilerini döner.")
    public ResponseEntity<UserResponse> getMyProfile(
            @Parameter(hidden = true) Authentication authentication) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.getMyProfile(email);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me")
    @Operation(summary = "Profilimi güncelle", description = "Giriş yapmış kullanıcının ad, soyad, telefon, adres, e-posta ve (öğrenci ise) IBAN bilgisini günceller.")
    public ResponseEntity<UserResponse> updateMyProfile(
            @Parameter(hidden = true) Authentication authentication,
            @Valid @RequestBody UpdateUserProfileRequest request) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.updateMyProfile(email, request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me/device-token")
    @Operation(summary = "Bildirim cihaz token'ını güncelle", description = "Giriş yapmış kullanıcının FCM device token bilgisini kaydeder veya günceller.")
    public ResponseEntity<UserResponse> updateMyDeviceToken(
            @Parameter(hidden = true) Authentication authentication,
            @Valid @RequestBody UpdateFcmTokenRequest request) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.updateMyFcmToken(email, request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/me/location")
    @Operation(summary = "Canlı konumumu güncelle", description = "Giriş yapmış kullanıcının enlem ve boylam bilgisini günceller.")
    public ResponseEntity<UserResponse> updateMyLocation(
            @Parameter(hidden = true) Authentication authentication,
            @Valid @RequestBody UpdateLocationRequest request) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.updateMyLocation(email, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/me")
    @Operation(summary = "Hesabımı dondur (soft-delete)", description = "Giriş yapmış kullanıcının hesabını soft-delete yapar (is_active=false).")
    public ResponseEntity<Void> deactivateMyAccount(
            @Parameter(hidden = true) Authentication authentication) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        userService.deactivateMyAccount(email);
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcısı oluştur", description = "Sadece INSTITUTION_ADMIN rolüne sahip kurum yöneticisinin, kendi kurumuna bağlı STUDENT veya ELDERLY kullanıcı oluşturmasını sağlar.")
    public ResponseEntity<UserResponse> createUser(
            Authentication authentication,
            @Valid @RequestBody CreateUserRequest request) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UserResponse userResponse = userService.createUser(email, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @GetMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcılarını listele", description = "Sadece INSTITUTION_ADMIN tarafından çağrılabilir. Her zaman sayfalı (paged) yanıt döner.")
    public ResponseEntity<UserPageResponse> listUsers(
            Authentication authentication,
            @Parameter(description = "İsteğe bağlı rol filtresi (STUDENT, ELDERLY)") @RequestParam(required = false) User.UserRole role,
            @Parameter(description = "Sayfa numarası (0'dan başlar)") @RequestParam(required = false) Integer page,
            @Parameter(description = "Sayfa boyutu (1-100)") @RequestParam(required = false) Integer size,
            @Parameter(description = "Arama metni (ad, soyad, email)") @RequestParam(required = false) String search,
            @Parameter(description = "Sıralama alanı: createdAt, firstName, lastName, email, role") @RequestParam(required = false) String sortBy,
            @Parameter(description = "Sıralama yönü: asc/desc") @RequestParam(required = false) String sortDir) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UserPageResponse users = userService.listUsersByInstitutionPaged(email, role, search, page, size, sortBy,
                sortDir);
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcısı detayını getir", description = "INSTITUTION_ADMIN kendi kurumundaki STUDENT/ELDERLY kullanıcı detayını getirir.")
    public ResponseEntity<UserResponse> getUserById(
            Authentication authentication,
            @PathVariable UUID id) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.getUserByIdForInstitution(email, id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcısını güncelle", description = "INSTITUTION_ADMIN kendi kurumundaki STUDENT/ELDERLY kullanıcı profilini günceller.")
    public ResponseEntity<UserResponse> updateUserById(
            Authentication authentication,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserProfileRequest request) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UserResponse response = userService.updateUserByIdForInstitution(email, id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcısını sil (soft-delete)", description = "INSTITUTION_ADMIN kendi kurumundaki STUDENT/ELDERLY kullanıcıyı soft-delete yapar.")
    public ResponseEntity<Void> deleteUserById(
            Authentication authentication,
            @PathVariable UUID id) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        userService.deleteUserByIdForInstitution(email, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/history")
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @Operation(summary = "Kurum kullanıcısı görev geçmişi", description = "INSTITUTION_ADMIN kendi kurumundaki STUDENT/ELDERLY kullanıcının görev geçmişini getirir.")
    public ResponseEntity<List<TaskResponse>> getUserHistoryById(
            Authentication authentication,
            @PathVariable UUID id) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        List<TaskResponse> response = userService.getUserHistoryForInstitution(email, id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/nearby-students")
    @PreAuthorize("hasRole('ELDERLY')")
    @Operation(summary = "Yakındaki müsait öğrencileri listele", description = "ELDERLY kullanıcının kendi kurumundaki müsait öğrencileri konuma göre listeler.")
    public ResponseEntity<List<UserResponse>> getNearbyStudents(
            Authentication authentication,
            @Parameter(description = "Opsiyonel enlem. Verilmezse kullanıcının kayıtlı enlemi kullanılır.") @RequestParam(required = false) Double latitude,
            @Parameter(description = "Opsiyonel boylam. Verilmezse kullanıcının kayıtlı boylamı kullanılır.") @RequestParam(required = false) Double longitude,
            @Parameter(description = "Arama yarıçapı (km). Varsayılan 5.0 km") @RequestParam(required = false) Double radiusKm) {
        String email = authentication != null ? authentication.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        List<UserResponse> nearby = userService.getNearbyAvailableStudents(email, latitude, longitude, radiusKm);
        return ResponseEntity.ok(nearby);
    }
}
