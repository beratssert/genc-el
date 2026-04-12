package com.gencel.backend.service;

import com.gencel.backend.dto.CreateUserRequest;
import com.gencel.backend.dto.UpdateFcmTokenRequest;
import com.gencel.backend.dto.UpdateLocationRequest;
import com.gencel.backend.dto.UpdateUserProfileRequest;
import com.gencel.backend.dto.UserPageResponse;
import com.gencel.backend.dto.UserResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.exception.UserNotFoundException;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserService")
class UserServiceTest {

        @Mock
        private UserRepository userRepository;

        @Mock
        private TaskRepository taskRepository;

        @Mock
        private PasswordEncoder passwordEncoder;

        @Mock
        private UserLocationRealtimePublisher userLocationRealtimePublisher;

        @InjectMocks
        private UserService userService;

        private Institution institution;
        private User institutionAdmin;
        private CreateUserRequest createStudentRequest;

        @BeforeEach
        void setUp() {
                institution = Institution.builder()
                                .id(UUID.randomUUID())
                                .name("Test Kurumu")
                                .region("Ankara")
                                .build();

                institutionAdmin = User.builder()
                                .id(UUID.randomUUID())
                                .institution(institution)
                                .role(User.UserRole.INSTITUTION_ADMIN)
                                .email("admin@kurum.gov.tr")
                                .passwordHash("encoded")
                                .firstName("Admin")
                                .lastName("User")
                                .isActive(true)
                                .build();

                createStudentRequest = CreateUserRequest.builder()
                                .role(User.UserRole.STUDENT)
                                .firstName("Ahmet")
                                .lastName("Yılmaz")
                                .email("ahmet@test.com")
                                .phoneNumber("0532 123 45 67")
                                .password("SecurePass123")
                                .iban("TR00 0000 0000 0000 0000 0000 00")
                                .build();
        }

        @Nested
        @DisplayName("createUser")
        class CreateUser {

                @Test
                @DisplayName("INSTITUTION_ADMIN ile geçerli STUDENT oluşturur")
                void shouldCreateStudentWhenAdminValid() {
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());
                        when(passwordEncoder.encode(anyString())).thenReturn("encoded123");

                        User savedStudent = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .email(createStudentRequest.getEmail())
                                        .firstName(createStudentRequest.getFirstName())
                                        .lastName(createStudentRequest.getLastName())
                                        .iban(createStudentRequest.getIban())
                                        .build();
                        when(userRepository.save(any(User.class))).thenReturn(savedStudent);

                        UserResponse response = userService.createUser("admin@kurum.gov.tr", createStudentRequest);

                        assertThat(response).isNotNull();
                        assertThat(response.getId()).isEqualTo(savedStudent.getId());
                        assertThat(response.getEmail()).isEqualTo("ahmet@test.com");
                        assertThat(response.getRole()).isEqualTo(User.UserRole.STUDENT);
                        verify(userRepository).save(any(User.class));
                }

                @Test
                @DisplayName("INSTITUTION_ADMIN ile geçerli ELDERLY oluşturur (IBAN olmadan)")
                void shouldCreateElderlyWhenAdminValid() {
                        createStudentRequest.setRole(User.UserRole.ELDERLY);
                        createStudentRequest.setIban(null);

                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());
                        when(passwordEncoder.encode(anyString())).thenReturn("encoded123");

                        User savedElderly = User.builder().id(UUID.randomUUID()).role(User.UserRole.ELDERLY).build();
                        when(userRepository.save(any(User.class))).thenReturn(savedElderly);

                        UserResponse response = userService.createUser("admin@kurum.gov.tr", createStudentRequest);

                        assertThat(response.getRole()).isEqualTo(User.UserRole.ELDERLY);
                }

                @Test
                @DisplayName("admin bulunamazsa exception fırlatır")
                void shouldThrowWhenAdminNotFound() {
                        when(userRepository.findByEmail("unknown@test.com")).thenReturn(Optional.empty());

                        assertThatThrownBy(() -> userService.createUser("unknown@test.com", createStudentRequest))
                                        .isInstanceOf(UserNotFoundException.class)
                                        .hasMessageContaining("User not found");
                }

                @Test
                @DisplayName("INSTITUTION_ADMIN değilse exception fırlatır")
                void shouldThrowWhenNotAdmin() {
                        institutionAdmin.setRole(User.UserRole.STUDENT);
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));

                        assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                                        .isInstanceOf(UnauthorizedActionException.class)
                                        .hasMessageContaining("INSTITUTION_ADMIN");
                }

                @Test
                @DisplayName("email zaten varsa exception fırlatır")
                void shouldThrowWhenEmailExists() {
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByEmail("ahmet@test.com"))
                                        .thenReturn(Optional.of(User.builder().build()));

                        assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                                        .isInstanceOf(IllegalArgumentException.class)
                                        .hasMessageContaining("already exists");
                }

                @Test
                @DisplayName("STUDENT için IBAN zorunludur")
                void shouldThrowWhenStudentWithoutIban() {
                        createStudentRequest.setIban(null);
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByEmail("ahmet@test.com")).thenReturn(Optional.empty());

                        assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                                        .isInstanceOf(IllegalArgumentException.class)
                                        .hasMessageContaining("IBAN");
                }

                @Test
                @DisplayName("INSTITUTION_ADMIN veya STUDENT dışı rol ile exception fırlatır")
                void shouldThrowWhenInvalidRole() {
                        createStudentRequest.setRole(User.UserRole.INSTITUTION_ADMIN);
                        // Rol kontrolü ilk yapılır, findByEmail çağrılmaz

                        assertThatThrownBy(() -> userService.createUser("admin@kurum.gov.tr", createStudentRequest))
                                        .isInstanceOf(IllegalArgumentException.class)
                                        .hasMessageContaining("Only STUDENT or ELDERLY");
                }
        }

        @Nested
        @DisplayName("listUsersByInstitution")
        class ListUsersByInstitution {

                @Test
                @DisplayName("admin kurumunun kullanıcılarını listeler")
                void shouldListUsersForAdminInstitution() {
                        User student = User.builder().id(UUID.randomUUID()).role(User.UserRole.STUDENT).build();
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByInstitutionIdOrderByCreatedAtDesc(institution.getId()))
                                        .thenReturn(List.of(student));

                        List<UserResponse> result = userService.listUsersByInstitution("admin@kurum.gov.tr", null);

                        assertThat(result).hasSize(1);
                        verify(userRepository).findByInstitutionIdOrderByCreatedAtDesc(institution.getId());
                }

                @Test
                @DisplayName("rol filtresi ile listeler")
                void shouldListUsersWithRoleFilter() {
                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(eq(institution.getId()),
                                        eq(User.UserRole.STUDENT)))
                                        .thenReturn(List.of());

                        List<UserResponse> result = userService.listUsersByInstitution("admin@kurum.gov.tr",
                                        User.UserRole.STUDENT);

                        assertThat(result).isEmpty();
                        verify(userRepository).findByInstitutionIdAndRoleOrderByCreatedAtDesc(institution.getId(),
                                        User.UserRole.STUDENT);
                }

                @Test
                @DisplayName("sayfalı listeleme arama ve sıralama ile çalışır")
                void shouldListUsersWithPaginationSearchAndSort() {
                        User student = User.builder()
                                        .id(UUID.randomUUID())
                                        .role(User.UserRole.STUDENT)
                                        .firstName("Ali")
                                        .email("ali@test.com")
                                        .build();

                        when(userRepository.findByEmail("admin@kurum.gov.tr"))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findManagedUsers(
                                        eq(institution.getId()),
                                        eq(User.UserRole.STUDENT),
                                        eq("%ali%"),
                                        eq(User.UserRole.INSTITUTION_ADMIN),
                                        any(PageRequest.class)))
                                        .thenReturn(new PageImpl<>(List.of(student), PageRequest.of(0, 10), 1));

                        UserPageResponse result = userService.listUsersByInstitutionPaged(
                                        "admin@kurum.gov.tr",
                                        User.UserRole.STUDENT,
                                        "ali",
                                        0,
                                        10,
                                        "createdAt",
                                        "desc");

                        assertThat(result.getItems()).hasSize(1);
                        assertThat(result.getTotalElements()).isEqualTo(1);
                        verify(userRepository).findManagedUsers(
                                        eq(institution.getId()),
                                        eq(User.UserRole.STUDENT),
                                        eq("%ali%"),
                                        eq(User.UserRole.INSTITUTION_ADMIN),
                                        any(PageRequest.class));
                }
        }

        @Nested
        @DisplayName("Profile operations")
        class ProfileOperations {

                @Test
                @DisplayName("getMyProfile mevcut kullanıcıyı döner")
                void shouldReturnMyProfile() {
                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));

                        UserResponse response = userService.getMyProfile(institutionAdmin.getEmail());

                        assertThat(response).isNotNull();
                        assertThat(response.getEmail()).isEqualTo(institutionAdmin.getEmail());
                        verify(userRepository).findByEmail(institutionAdmin.getEmail());
                }

                @Test
                @DisplayName("getMyProfile kullanıcı bulunamazsa exception fırlatır")
                void shouldThrowWhenUserNotFoundOnGetProfile() {
                        when(userRepository.findByEmail("unknown@test.com")).thenReturn(Optional.empty());

                        assertThatThrownBy(() -> userService.getMyProfile("unknown@test.com"))
                                        .isInstanceOf(UserNotFoundException.class)
                                        .hasMessageContaining("User not found");
                }

                @Test
                @DisplayName("updateMyProfile alanları günceller")
                void shouldUpdateMyProfileFields() {
                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

                        UpdateUserProfileRequest request = UpdateUserProfileRequest.builder()
                                        .firstName("YeniAd")
                                        .lastName("YeniSoyad")
                                        .phoneNumber("0500 000 00 00")
                                        .address("Yeni adres")
                                        .build();

                        UserResponse response = userService.updateMyProfile(institutionAdmin.getEmail(), request);

                        assertThat(response.getFirstName()).isEqualTo("YeniAd");
                        assertThat(response.getLastName()).isEqualTo("YeniSoyad");
                        assertThat(response.getPhoneNumber()).isEqualTo("0500 000 00 00");
                        assertThat(response.getAddress()).isEqualTo("Yeni adres");
                        verify(userRepository).save(any(User.class));
                }

                @Test
                @DisplayName("updateMyFcmToken token kaydeder")
                void shouldUpdateMyFcmToken() {
                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

                        UpdateFcmTokenRequest request = UpdateFcmTokenRequest.builder()
                                        .fcmToken("  token-123  ")
                                        .build();

                        UserResponse response = userService.updateMyFcmToken(institutionAdmin.getEmail(), request);

                        assertThat(response.getFcmToken()).isEqualTo("token-123");
                        verify(userRepository).save(any(User.class));
                }

                @Test
                @DisplayName("updateMyLocation kullanıcının konumunu günceller")
                void shouldUpdateMyLocation() {
                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

                        UpdateLocationRequest request = UpdateLocationRequest.builder()
                                        .latitude(39.9334)
                                        .longitude(32.8597)
                                        .build();

                        UserResponse response = userService.updateMyLocation(institutionAdmin.getEmail(), request);

                        assertThat(response.getLatitude()).isEqualTo(39.9334);
                        assertThat(response.getLongitude()).isEqualTo(32.8597);
                        verify(userRepository).save(any(User.class));
                        verify(userLocationRealtimePublisher).publishLocationUpdated(any(User.class));
                }

                @Test
                @DisplayName("updateMyLocation kullanıcı bulunamazsa exception fırlatır")
                void shouldThrowWhenUserNotFoundOnUpdateLocation() {
                        when(userRepository.findByEmail("unknown@test.com")).thenReturn(Optional.empty());

                        UpdateLocationRequest request = UpdateLocationRequest.builder()
                                        .latitude(39.9)
                                        .longitude(32.8)
                                        .build();

                        assertThatThrownBy(() -> userService.updateMyLocation("unknown@test.com", request))
                                        .isInstanceOf(UserNotFoundException.class)
                                        .hasMessageContaining("User not found");
                }

                @Test
                @DisplayName("STUDENT için boş IBAN ile updateMyProfile exception fırlatır")
                void shouldThrowWhenStudentUpdatesWithBlankIban() {
                        User student = User.builder()
                                        .id(UUID.randomUUID())
                                        .role(User.UserRole.STUDENT)
                                        .email("student@test.com")
                                        .build();
                        when(userRepository.findByEmail(student.getEmail())).thenReturn(Optional.of(student));

                        UpdateUserProfileRequest request = UpdateUserProfileRequest.builder()
                                        .iban("   ")
                                        .build();

                        assertThatThrownBy(() -> userService.updateMyProfile(student.getEmail(), request))
                                        .isInstanceOf(IllegalArgumentException.class)
                                        .hasMessageContaining("IBAN is required for STUDENT role");
                }

                @Test
                @DisplayName("deactivateMyAccount kullanıcıyı soft-delete eder (repository.delete çağrılır)")
                void shouldDeactivateMyAccount() {
                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));

                        userService.deactivateMyAccount(institutionAdmin.getEmail());

                        verify(userRepository).delete(institutionAdmin);
                }
        }

        @Nested
        @DisplayName("Managed user operations")
        class ManagedUserOperations {

                @Test
                @DisplayName("admin kurum içindeki kullanıcı detayını alır")
                void shouldGetManagedUserById() {
                        User target = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .email("target@test.com")
                                        .build();

                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByIdAndInstitutionId(target.getId(), institution.getId()))
                                        .thenReturn(Optional.of(target));

                        UserResponse response = userService.getUserByIdForInstitution(institutionAdmin.getEmail(),
                                        target.getId());

                        assertThat(response.getEmail()).isEqualTo("target@test.com");
                }

                @Test
                @DisplayName("admin kurum içindeki kullanıcıyı günceller")
                void shouldUpdateManagedUser() {
                        User target = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.ELDERLY)
                                        .firstName("Eski")
                                        .email("target2@test.com")
                                        .build();

                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByIdAndInstitutionId(target.getId(), institution.getId()))
                                        .thenReturn(Optional.of(target));
                        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

                        UpdateUserProfileRequest request = UpdateUserProfileRequest.builder()
                                        .firstName("Yeni")
                                        .phoneNumber("0500 123 45 67")
                                        .build();

                        UserResponse response = userService.updateUserByIdForInstitution(institutionAdmin.getEmail(),
                                        target.getId(), request);

                        assertThat(response.getFirstName()).isEqualTo("Yeni");
                        assertThat(response.getPhoneNumber()).isEqualTo("0500 123 45 67");
                        verify(userRepository).save(any(User.class));
                }

                @Test
                @DisplayName("admin kurum içindeki kullanıcıyı soft-delete eder")
                void shouldDeleteManagedUser() {
                        User target = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .build();

                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByIdAndInstitutionId(target.getId(), institution.getId()))
                                        .thenReturn(Optional.of(target));

                        userService.deleteUserByIdForInstitution(institutionAdmin.getEmail(), target.getId());

                        verify(userRepository).delete(target);
                }

                @Test
                @DisplayName("admin kurum içindeki kullanıcının görev geçmişini alır")
                void shouldGetManagedUserHistory() {
                        User target = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .build();

                        Task task = Task.builder()
                                        .id(UUID.randomUUID())
                                        .requester(target)
                                        .status(Task.TaskStatus.COMPLETED)
                                        .build();

                        when(userRepository.findByEmail(institutionAdmin.getEmail()))
                                        .thenReturn(Optional.of(institutionAdmin));
                        when(userRepository.findByIdAndInstitutionId(target.getId(), institution.getId()))
                                        .thenReturn(Optional.of(target));
                        when(taskRepository.findByRequesterIdOrVolunteerIdOrderByUpdatedAtDesc(target.getId(),
                                        target.getId()))
                                        .thenReturn(List.of(task));

                        var result = userService.getUserHistoryForInstitution(institutionAdmin.getEmail(),
                                        target.getId());

                        assertThat(result).hasSize(1);
                        assertThat(result.get(0).getStatus()).isEqualTo(Task.TaskStatus.COMPLETED.name());
                }
        }

        @Nested
        @DisplayName("getNearbyAvailableStudents")
        class NearbyStudents {

                @Test
                @DisplayName("ELDERLY kullanıcı için yakındaki öğrencileri döner")
                void shouldReturnNearbyStudentsForElderly() {
                        User elderly = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.ELDERLY)
                                        .email("elderly@test.com")
                                        .latitude(39.9334)
                                        .longitude(32.8597)
                                        .build();

                        User student = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .email("nearby.student@test.com")
                                        .firstName("Nearby")
                                        .lastName("Student")
                                        .build();

                        when(userRepository.findByEmail(elderly.getEmail())).thenReturn(Optional.of(elderly));
                        when(userRepository.findNearbyAvailableStudents(institution.getId(), elderly.getId(),
                                        elderly.getLatitude(),
                                        elderly.getLongitude(), 5.0)).thenReturn(List.of(student));

                        List<UserResponse> response = userService.getNearbyAvailableStudents(elderly.getEmail(), null,
                                        null, null);

                        assertThat(response).hasSize(1);
                        assertThat(response.get(0).getEmail()).isEqualTo("nearby.student@test.com");
                        verify(userRepository).findNearbyAvailableStudents(institution.getId(), elderly.getId(),
                                        elderly.getLatitude(),
                                        elderly.getLongitude(), 5.0);
                }

                @Test
                @DisplayName("ELDERLY dışı kullanıcı için exception fırlatır")
                void shouldThrowWhenUserIsNotElderly() {
                        User student = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.STUDENT)
                                        .email("student@test.com")
                                        .build();

                        when(userRepository.findByEmail(student.getEmail())).thenReturn(Optional.of(student));

                        assertThatThrownBy(() -> userService.getNearbyAvailableStudents(student.getEmail(), 39.9, 32.8,
                                        5.0))
                                        .isInstanceOf(UnauthorizedActionException.class)
                                        .hasMessageContaining("Only ELDERLY users");
                }

                @Test
                @DisplayName("radiusKm 0 veya negatifse exception fırlatır")
                void shouldThrowWhenRadiusIsInvalid() {
                        User elderly = User.builder()
                                        .id(UUID.randomUUID())
                                        .institution(institution)
                                        .role(User.UserRole.ELDERLY)
                                        .email("elderly2@test.com")
                                        .build();

                        when(userRepository.findByEmail(elderly.getEmail())).thenReturn(Optional.of(elderly));

                        assertThatThrownBy(() -> userService.getNearbyAvailableStudents(elderly.getEmail(), 39.9, 32.8,
                                        0.0))
                                        .isInstanceOf(IllegalArgumentException.class)
                                        .hasMessageContaining("radiusKm");
                }
        }
}
