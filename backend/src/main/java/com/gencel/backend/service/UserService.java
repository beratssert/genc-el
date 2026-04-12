package com.gencel.backend.service;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.dto.UpdateFcmTokenRequest;
import com.gencel.backend.dto.UpdateLocationRequest;
import com.gencel.backend.dto.UserPageResponse;
import com.gencel.backend.dto.UpdateUserProfileRequest;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.exception.UserNotFoundException;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final TaskRepository taskRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserLocationRealtimePublisher userLocationRealtimePublisher;

    private static final Set<String> ALLOWED_USER_SORT_FIELDS = new HashSet<>(
            Arrays.asList("createdAt", "firstName", "lastName", "email", "role"));

    @Transactional
    public UserResponse createUser(String currentUserEmail, CreateUserRequest request) {
        // Validate that only STUDENT or ELDERLY roles can be created
        if (request.getRole() != User.UserRole.STUDENT && request.getRole() != User.UserRole.ELDERLY) {
            throw new IllegalArgumentException("Only STUDENT or ELDERLY roles can be created through this endpoint");
        }

        // Fetch current user (institution admin) and validate role
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (currentUser.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new UnauthorizedActionException("Only INSTITUTION_ADMIN can create users");
        }

        var targetInstitution = currentUser.getInstitution();

        if (targetInstitution == null || targetInstitution.getId() == null) {
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
                .institution(targetInstitution)
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
     * INSTITUTION_ADMIN sees only its own institution users.
     */
    public List<UserResponse> listUsersByInstitution(String currentUserEmail, User.UserRole roleFilter) {
        User currentUser = getInstitutionAdminOrThrow(currentUserEmail);
        UUID institutionId = currentUser.getInstitution().getId();

        List<User> users = roleFilter == null
                ? userRepository.findByInstitutionIdOrderByCreatedAtDesc(institutionId)
                : userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(institutionId, roleFilter);

        // Institution admin sees only non-admin users of its own institution
        return users.stream()
                .filter(user -> user.getRole() != User.UserRole.INSTITUTION_ADMIN)
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    public UserPageResponse listUsersByInstitutionPaged(
            String currentUserEmail,
            User.UserRole roleFilter,
            String search,
            Integer page,
            Integer size,
            String sortBy,
            String sortDir) {
        User currentUser = getInstitutionAdminOrThrow(currentUserEmail);

        int effectivePage = page == null ? 0 : page;
        int effectiveSize = size == null ? 20 : size;
        String effectiveSortBy = (sortBy == null || sortBy.isBlank()) ? "createdAt" : sortBy;
        String effectiveSortDir = (sortDir == null || sortDir.isBlank()) ? "desc" : sortDir;

        if (effectivePage < 0) {
            throw new IllegalArgumentException("page must be >= 0");
        }
        if (effectiveSize <= 0 || effectiveSize > 100) {
            throw new IllegalArgumentException("size must be between 1 and 100");
        }
        if (!ALLOWED_USER_SORT_FIELDS.contains(effectiveSortBy)) {
            throw new IllegalArgumentException("sortBy is not supported");
        }

        Sort.Direction direction = "asc".equalsIgnoreCase(effectiveSortDir)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        Pageable pageable = PageRequest.of(effectivePage, effectiveSize, Sort.by(direction, effectiveSortBy));
        String normalizedSearch = (search == null || search.isBlank()) ? null : search.trim().toLowerCase();
        String searchPattern = normalizedSearch == null ? null : "%" + normalizedSearch + "%";

        Page<User> usersPage = userRepository.findManagedUsers(
                currentUser.getInstitution().getId(),
                roleFilter,
                searchPattern,
                User.UserRole.INSTITUTION_ADMIN,
                pageable);

        List<UserResponse> items = usersPage.getContent().stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());

        return UserPageResponse.builder()
                .items(items)
                .page(usersPage.getNumber())
                .size(usersPage.getSize())
                .totalElements(usersPage.getTotalElements())
                .totalPages(usersPage.getTotalPages())
                .hasNext(usersPage.hasNext())
                .hasPrevious(usersPage.hasPrevious())
                .build();
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByIdForInstitution(String currentUserEmail, UUID userId) {
        User admin = getInstitutionAdminOrThrow(currentUserEmail);
        User targetUser = getManagedUserOrThrow(admin.getInstitution().getId(), userId);
        return mapToUserResponse(targetUser);
    }

    @Transactional
    public UserResponse updateUserByIdForInstitution(String currentUserEmail, UUID userId,
            UpdateUserProfileRequest request) {
        User admin = getInstitutionAdminOrThrow(currentUserEmail);
        User targetUser = getManagedUserOrThrow(admin.getInstitution().getId(), userId);

        if (request.getFirstName() != null) {
            targetUser.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            targetUser.setLastName(request.getLastName());
        }
        if (request.getPhoneNumber() != null) {
            targetUser.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getEmail() != null) {
            targetUser.setEmail(request.getEmail());
        }
        if (request.getAddress() != null) {
            targetUser.setAddress(request.getAddress());
        }
        if (request.getIban() != null) {
            if (targetUser.getRole() == User.UserRole.STUDENT && request.getIban().isBlank()) {
                throw new IllegalArgumentException("IBAN is required for STUDENT role");
            }
            targetUser.setIban(request.getIban());
        }

        targetUser = userRepository.save(targetUser);
        return mapToUserResponse(targetUser);
    }

    @Transactional
    public void deleteUserByIdForInstitution(String currentUserEmail, UUID userId) {
        User admin = getInstitutionAdminOrThrow(currentUserEmail);
        User targetUser = getManagedUserOrThrow(admin.getInstitution().getId(), userId);
        userRepository.delete(targetUser);
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> getUserHistoryForInstitution(String currentUserEmail, UUID userId) {
        User admin = getInstitutionAdminOrThrow(currentUserEmail);
        User targetUser = getManagedUserOrThrow(admin.getInstitution().getId(), userId);

        return taskRepository.findByRequesterIdOrVolunteerIdOrderByUpdatedAtDesc(targetUser.getId(), targetUser.getId())
                .stream()
                .filter(task -> task.getRequester() != null
                        && task.getRequester().getInstitution() != null
                        && admin.getInstitution().getId().equals(task.getRequester().getInstitution().getId()))
                .map(this::mapToTaskResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getNearbyAvailableStudents(String currentUserEmail, Double latitude, Double longitude,
            Double radiusKm) {
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (currentUser.getRole() != User.UserRole.ELDERLY) {
            throw new UnauthorizedActionException("Only ELDERLY users can discover nearby students");
        }

        if (currentUser.getInstitution() == null || currentUser.getInstitution().getId() == null) {
            throw new IllegalArgumentException("User has no institution");
        }

        double effectiveRadius = radiusKm == null ? 5.0 : radiusKm;
        if (effectiveRadius <= 0) {
            throw new IllegalArgumentException("radiusKm must be greater than 0");
        }

        Double effectiveLat = latitude != null ? latitude : currentUser.getLatitude();
        Double effectiveLon = longitude != null ? longitude : currentUser.getLongitude();

        List<User> users = userRepository.findNearbyAvailableStudents(
                currentUser.getInstitution().getId(),
                currentUser.getId(),
                effectiveLat,
                effectiveLon,
                effectiveRadius);

        return users.stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserResponse getMyProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        return mapToUserResponse(user);
    }

    @Transactional
    public UserResponse updateMyProfile(String email, UpdateUserProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

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
    public UserResponse updateMyFcmToken(String email, UpdateFcmTokenRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        user.setFcmToken(request.getFcmToken().trim());
        user = userRepository.save(user);
        return mapToUserResponse(user);
    }

    @Transactional
    public UserResponse updateMyLocation(String email, UpdateLocationRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        user.setLatitude(request.getLatitude());
        user.setLongitude(request.getLongitude());

        user = userRepository.save(user);
        userLocationRealtimePublisher.publishLocationUpdated(user);
        return mapToUserResponse(user);
    }

    @Transactional
    public void deactivateMyAccount(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
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
                .fcmToken(user.getFcmToken())
                .isActive(user.getIsActive())
                .iban(user.getIban())
                .createdAt(user.getCreatedAt())
                .build();
    }

    private TaskResponse mapToTaskResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .requesterId(task.getRequester() != null ? task.getRequester().getId() : null)
                .volunteerId(task.getVolunteer() != null ? task.getVolunteer().getId() : null)
                .status(task.getStatus() != null ? task.getStatus().name() : null)
                .shoppingList(task.getShoppingList())
                .note(task.getNote())
                .totalAmountGiven(task.getTotalAmountGiven())
                .changeAmount(task.getChangeAmount())
                .receiptImageUrl(task.getReceiptImageUrl())
                .startConfirmed(task.getStartConfirmed())
                .deliveryConfirmed(task.getDeliveryConfirmed())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }

    private User getInstitutionAdminOrThrow(String currentUserEmail) {
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (currentUser.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new UnauthorizedActionException("Only INSTITUTION_ADMIN can manage users");
        }

        if (currentUser.getInstitution() == null || currentUser.getInstitution().getId() == null) {
            throw new IllegalArgumentException("Admin user has no institution");
        }

        return currentUser;
    }

    private User getManagedUserOrThrow(UUID institutionId, UUID userId) {
        User targetUser = userRepository.findByIdAndInstitutionId(userId, institutionId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (targetUser.getRole() == User.UserRole.INSTITUTION_ADMIN
                || targetUser.getRole() == User.UserRole.SYSTEM_ADMIN) {
            throw new UnauthorizedActionException("Cannot manage admin users from this endpoint");
        }

        return targetUser;
    }
}
