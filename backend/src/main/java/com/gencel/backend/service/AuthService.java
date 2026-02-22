package com.gencel.backend.service;

import com.gencel.backend.dto.LoginRequest;
import com.gencel.backend.dto.LoginResponse;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import com.gencel.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public LoginResponse login(LoginRequest request) {
        // Fetch user from database (single query), bypassing @SQLRestriction to check disabled users
        User user = userRepository.findByEmailIncludingDisabled(request.getEmail())
                .orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException("Kullanıcı bulunamadı"));

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
                        new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_" + user.getRole().name())))
                .build();
        
        // Generate token
        String token = jwtService.generateToken(userDetails);

        return LoginResponse.builder()
                .token(token)
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }
}
