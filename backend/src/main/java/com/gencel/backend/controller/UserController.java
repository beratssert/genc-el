package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.User;
import com.gencel.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserResponse userResponse = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @GetMapping
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    public ResponseEntity<List<UserResponse>> listUsers(
            Authentication authentication,
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
