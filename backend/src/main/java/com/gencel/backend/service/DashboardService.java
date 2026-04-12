package com.gencel.backend.service;

import com.gencel.backend.dto.DashboardStatsResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private static final double MAX_BURSARY_AMOUNT = 10000.0;
    private static final int REQUIRED_TASKS_FOR_MAX = 10;

    private final UserRepository userRepository;
    private final TaskRepository taskRepository;

    @Transactional(readOnly = true)
    public DashboardStatsResponse getDashboardStats(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getRole() == User.UserRole.STUDENT) {
            return buildStudentStats(user);
        } else if (user.getRole() == User.UserRole.INSTITUTION_ADMIN) {
            return buildInstitutionStats(user);
        }

        // Elderly or other roles: currently no special stats
        return DashboardStatsResponse.builder().build();
    }

    private DashboardStatsResponse buildStudentStats(User student) {
        UUID studentId = student.getId();

        long totalCompletedTasks = taskRepository
                .countByVolunteerIdAndStatus(studentId, Task.TaskStatus.COMPLETED);

        YearMonth currentMonth = YearMonth.from(LocalDate.now());
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(LocalTime.MAX);

        long completedThisMonth = taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                studentId,
                Task.TaskStatus.COMPLETED,
                startOfMonth,
                endOfMonth
        );

        double estimatedBursary = calculateEstimatedBursary((int) completedThisMonth);

        return DashboardStatsResponse.builder()
                .totalCompletedTasks(totalCompletedTasks)
                .estimatedCurrentMonthBursary(estimatedBursary)
                .build();
    }

    private DashboardStatsResponse buildInstitutionStats(User admin) {
        if (admin.getInstitution() == null || admin.getInstitution().getId() == null) {
            throw new RuntimeException("Admin user has no institution");
        }
        UUID institutionId = admin.getInstitution().getId();

        long totalStudents = userRepository
                .findByInstitutionIdAndRoleOrderByCreatedAtDesc(institutionId, User.UserRole.STUDENT)
                .size();
        long totalElderlies = userRepository
                .findByInstitutionIdAndRoleOrderByCreatedAtDesc(institutionId, User.UserRole.ELDERLY)
                .size();

        YearMonth currentMonth = YearMonth.from(LocalDate.now());
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(LocalTime.MAX);

        long totalTasksThisMonth = taskRepository
                .countByVolunteer_Institution_IdAndUpdatedAtBetween(
                        institutionId,
                        startOfMonth,
                        endOfMonth
                );

        return DashboardStatsResponse.builder()
                .totalStudents(totalStudents)
                .totalElderlies(totalElderlies)
                .totalTasksThisMonth(totalTasksThisMonth)
                .build();
    }

    private double calculateEstimatedBursary(int completedTaskCount) {
        if (completedTaskCount >= REQUIRED_TASKS_FOR_MAX) {
            return MAX_BURSARY_AMOUNT;
        } else if (completedTaskCount > 0) {
            return (completedTaskCount / (double) REQUIRED_TASKS_FOR_MAX) * MAX_BURSARY_AMOUNT;
        }
        return 0.0;
    }
}

