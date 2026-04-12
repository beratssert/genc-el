package com.gencel.backend.service;

import com.gencel.backend.dto.ChangePasswordRequest;
import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.dto.RefreshTokenResponse;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import com.gencel.backend.security.JwtService;
import org.springframework.security.authentication.BadCredentialsException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public LoginResponse userLogin(LoginRequest request) {
        return loginWithRoles(request, java.util.List.of(User.UserRole.STUDENT, User.UserRole.ELDERLY));
    }

    public LoginResponse institutionLogin(LoginRequest request) {
        return loginWithRoles(request, java.util.List.of(User.UserRole.INSTITUTION_ADMIN));
    }

    public LoginResponse superAdminLogin(LoginRequest request) {
        return loginWithRoles(request, java.util.List.of(User.UserRole.SYSTEM_ADMIN));
    }

    public RefreshTokenResponse refreshToken(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException(
                        "Kullanıcı bulunamadı"));

        UserDetails userDetails = org.springframework.security.core.userdetails.User.builder()
                .username(user.getEmail())
                .password(user.getPasswordHash())
                .authorities(java.util.Collections.singletonList(
                        new org.springframework.security.core.authority.SimpleGrantedAuthority(
                                "ROLE_" + user.getRole().name())))
                .build();

        String token = jwtService.generateToken(userDetails);
        return RefreshTokenResponse.builder()
                .token(token)
                .build();
    }

    @Transactional
    public void changePassword(String email, ChangePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException(
                        "Kullanıcı bulunamadı"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Current password is incorrect");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("New password must be different from current password");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    private LoginResponse loginWithRoles(LoginRequest request, java.util.List<User.UserRole> allowedRoles) {
        // Fetch user from database (single query), bypassing @SQLRestriction to check
        // disabled users
        User user = userRepository.findByEmailIncludingDisabled(request.getEmail())
                .orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException(
                        "Kullanıcı bulunamadı"));

        // Check if role is allowed
        if (!allowedRoles.contains(user.getRole())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Yetkisiz giriş denemesi");
        }

        // Check if user is active
        if (!user.getIsActive()) {
            throw new org.springframework.security.authentication.DisabledException("Hesap pasif durumda");
        }

        // Authenticate manually to avoid duplicate database queries
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Hatalı şifre");
        }

        // Generate UserDetails for JWT
        UserDetails userDetails = org.springframework.security.core.userdetails.User.builder()
                .username(user.getEmail())
                .password(user.getPasswordHash())
                .authorities(java.util.Collections.singletonList(
                        new org.springframework.security.core.authority.SimpleGrantedAuthority(
                                "ROLE_" + user.getRole().name())))
                .build();

        // Generate token
        String token = jwtService.generateToken(userDetails);

        return LoginResponse.builder()
                .token(token)
                .email(user.getEmail())
                .role(user.getRole().name())
                .userId(user.getId().toString())
                .institutionId(user.getInstitution() != null ? user.getInstitution().getId().toString() : null)
                .build();
    }
}
