package com.gencel.backend.service;

import com.gencel.backend.dto.DashboardStatsResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
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

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("DashboardService")
class DashboardServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private DashboardService dashboardService;

    private Institution institution;
    private User studentUser;
    private User adminUser;

    @BeforeEach
    void setUp() {
        institution = Institution.builder()
                .id(UUID.randomUUID())
                .name("Test Institution")
                .build();

        studentUser = User.builder()
                .id(UUID.randomUUID())
                .institution(institution)
                .role(User.UserRole.STUDENT)
                .email("student@test.com")
                .build();

        adminUser = User.builder()
                .id(UUID.randomUUID())
                .institution(institution)
                .role(User.UserRole.INSTITUTION_ADMIN)
                .email("admin@test.com")
                .build();
    }

    @Nested
    @DisplayName("getDashboardStats for student")
    class StudentStats {

        @Test
        @DisplayName("öğrenci için toplam tamamlanan görev ve bu ayki tahmini bursu hesaplar")
        void shouldReturnStudentStats() {
            when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
            when(taskRepository.countByVolunteerIdAndStatus(studentUser.getId(), Task.TaskStatus.COMPLETED))
                    .thenReturn(15L);
            when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                    eq(studentUser.getId()),
                    eq(Task.TaskStatus.COMPLETED),
                    any(),
                    any()))
                    .thenReturn(5L);

            DashboardStatsResponse stats = dashboardService.getDashboardStats(studentUser.getEmail());

            assertThat(stats.getTotalCompletedTasks()).isEqualTo(15L);
            assertThat(stats.getEstimatedCurrentMonthBursary()).isEqualTo(5000.0);
        }
    }

    @Nested
    @DisplayName("getDashboardStats for institution admin")
    class InstitutionStats {

        @Test
        @DisplayName("kurum yöneticisi için öğrenci/yaşlı sayısı ve bu ayki görev sayısını hesaplar")
        void shouldReturnInstitutionStats() {
            when(userRepository.findByEmail(adminUser.getEmail())).thenReturn(Optional.of(adminUser));
            when(userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(
                    institution.getId(), User.UserRole.STUDENT))
                    .thenReturn(List.of(new User(), new User()));
            when(userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(
                    institution.getId(), User.UserRole.ELDERLY))
                    .thenReturn(List.of(new User()));
            when(taskRepository.countByVolunteer_Institution_IdAndUpdatedAtBetween(
                    eq(institution.getId()),
                    any(),
                    any()))
                    .thenReturn(7L);

            DashboardStatsResponse stats = dashboardService.getDashboardStats(adminUser.getEmail());

            assertThat(stats.getTotalStudents()).isEqualTo(2L);
            assertThat(stats.getTotalElderlies()).isEqualTo(1L);
            assertThat(stats.getTotalTasksThisMonth()).isEqualTo(7L);
        }

        @Test
        @DisplayName("kurum bilgisi olmayan admin için exception fırlatır")
        void shouldThrowWhenAdminHasNoInstitution() {
            adminUser.setInstitution(null);
            when(userRepository.findByEmail(adminUser.getEmail())).thenReturn(Optional.of(adminUser));

            assertThatThrownBy(() -> dashboardService.getDashboardStats(adminUser.getEmail()))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Admin user has no institution");
        }
    }

    @Test
    @DisplayName("kullanıcı bulunamazsa exception fırlatır")
    void shouldThrowWhenUserNotFound() {
        when(userRepository.findByEmail("unknown@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> dashboardService.getDashboardStats("unknown@test.com"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("User not found");
    }
}

