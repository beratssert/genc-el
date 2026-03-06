package com.gencel.backend.service;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.UpdateUserProfileRequest;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserResponse createUser(String currentUserEmail, CreateUserRequest request) {
        // Validate that only STUDENT or ELDERLY roles can be created
        if (request.getRole() != User.UserRole.STUDENT && request.getRole() != User.UserRole.ELDERLY) {
            throw new IllegalArgumentException("Only STUDENT or ELDERLY roles can be created through this endpoint");
        }

        // Fetch current user (institution admin) and validate role
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (currentUser.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new IllegalArgumentException("Only INSTITUTION_ADMIN can create users");
        }

        if (currentUser.getInstitution() == null || currentUser.getInstitution().getId() == null) {
            throw new IllegalArgumentException("Admin user has no institution");
        }

        // Check if email already exists
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("User with email " + request.getEmail() + " already exists");
        }

        // Validate IBAN for students
        if (request.getRole() == User.UserRole.STUDENT && (request.getIban() == null || request.getIban().isBlank())) {
            throw new IllegalArgumentException("IBAN is required for STUDENT role");
        }

        // Create user entity
        User user = User.builder()
                .institution(currentUser.getInstitution())
                .role(request.getRole())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .phoneNumber(request.getPhoneNumber())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .address(request.getAddress())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .iban(request.getIban())
                .isActive(true)
                .build();

        user = userRepository.save(user);

        return mapToUserResponse(user);
    }

    /**
     * Lists users belonging to the same institution as the current admin.
     * Only INSTITUTION_ADMIN can call this; they see only their institution's users.
     */
    public List<UserResponse> listUsersByInstitution(String currentUserEmail, User.UserRole roleFilter) {
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (currentUser.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new IllegalArgumentException("Only INSTITUTION_ADMIN can list users");
        }

        if (currentUser.getInstitution() == null || currentUser.getInstitution().getId() == null) {
            throw new IllegalArgumentException("Admin user has no institution");
        }

        UUID institutionId = currentUser.getInstitution().getId();
        List<User> users = roleFilter == null
                ? userRepository.findByInstitutionIdOrderByCreatedAtDesc(institutionId)
                : userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(institutionId, roleFilter);

        return users.stream()
                .filter(user -> user.getRole() != User.UserRole.INSTITUTION_ADMIN) // Adminleri (kendini) listeden çıkart
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserResponse getMyProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        return mapToUserResponse(user);
    }

    @Transactional
    public UserResponse updateMyProfile(String email, UpdateUserProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getPhoneNumber() != null) {
            user.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getEmail() != null) {
            user.setEmail(request.getEmail());
        }
        if (request.getAddress() != null) {
            user.setAddress(request.getAddress());
        }
        if (request.getIban() != null) {
            // IBAN sadece öğrenci için anlamlı; öğrenci ise boş bırakılamaz
            if (user.getRole() == User.UserRole.STUDENT && request.getIban().isBlank()) {
                throw new IllegalArgumentException("IBAN is required for STUDENT role");
            }
            user.setIban(request.getIban());
        }

        user = userRepository.save(user);
        return mapToUserResponse(user);
    }

    @Transactional
    public void deactivateMyAccount(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        // Soft-delete: @SQLDelete ile is_active=false olarak işaretlenecek
        userRepository.delete(user);
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .institutionId(user.getInstitution() != null ? user.getInstitution().getId() : null)
                .role(user.getRole())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .phoneNumber(user.getPhoneNumber())
                .email(user.getEmail())
                .address(user.getAddress())
                .latitude(user.getLatitude())
                .longitude(user.getLongitude())
                .isActive(user.getIsActive())
                .iban(user.getIban())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
