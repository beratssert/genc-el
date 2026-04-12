package com.gencel.backend.service;

import com.gencel.backend.dto.BursaryPaymentRequest;
import com.gencel.backend.dto.BursaryResponse;
import com.gencel.backend.entity.BursaryHistory;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.BursaryHistoryRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BursaryService {

    private final BursaryHistoryRepository bursaryHistoryRepository;
    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    private static final double MAX_BURSARY_AMOUNT = 10000.0;
    private static final int REQUIRED_TASKS_FOR_MAX = 10;

    /**
     * Automated job running at 00:00 on the 1st day of every month.
     * Calculates the bursaries for the PREVIOUS month.
     */
    @Scheduled(cron = "0 0 0 1 * ?")
    @Transactional
    public void calculatePreviousMonthBursariesAutomated() {
        LocalDate today = LocalDate.now();
        LocalDate lastMonthDate = today.minusMonths(1);
        int year = lastMonthDate.getYear();
        int month = lastMonthDate.getMonthValue();

        log.info("Starting automated bursary calculation for {}/{}", month, year);
        calculateBursariesForMonth(year, month);
        log.info("Finished automated bursary calculation for {}/{}", month, year);
    }

    /**
     * Manual or programmed trigger to calculate bursaries for all students in a
     * specific month.
     */
    @Transactional
    public void calculateBursariesForMonth(int year, int month) {
        // Only run for students
        List<User> students = userRepository.findByRole(User.UserRole.STUDENT);

        YearMonth targetMonth = YearMonth.of(year, month);
        LocalDateTime startOfMonth = targetMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = targetMonth.atEndOfMonth().atTime(LocalTime.MAX);

        for (User student : students) {
            long completedTaskCount = taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                    student.getId(),
                    Task.TaskStatus.COMPLETED,
                    startOfMonth,
                    endOfMonth);

            double calculatedAmount = calculateAmount((int) completedTaskCount);

            Optional<BursaryHistory> existingRecordOpt = bursaryHistoryRepository
                    .findByStudentIdAndYearAndMonth(student.getId(), year, month);

            BursaryHistory record;
            if (existingRecordOpt.isPresent()) {
                record = existingRecordOpt.get();
                // Only update if it hasn't been explicitly paid yet
                if (!Boolean.TRUE.equals(record.getIsPaid())) {
                    record.setCompletedTaskCount((int) completedTaskCount);
                    record.setCalculatedAmount(calculatedAmount);
                }
            } else {
                record = BursaryHistory.builder()
                        .student(student)
                        .year(year)
                        .month(month)
                        .completedTaskCount((int) completedTaskCount)
                        .calculatedAmount(calculatedAmount)
                        .isPaid(false)
                        .build();
            }

            bursaryHistoryRepository.save(record);
        }
    }

    private double calculateAmount(int completedTaskCount) {
        if (completedTaskCount >= REQUIRED_TASKS_FOR_MAX) {
            return MAX_BURSARY_AMOUNT;
        } else if (completedTaskCount > 0) {
            return (completedTaskCount / (double) REQUIRED_TASKS_FOR_MAX) * MAX_BURSARY_AMOUNT;
        }
        return 0.0;
    }

    @Transactional(readOnly = true)
    public List<BursaryResponse> getStudentBursaryHistory(String email) {
        User student = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.STUDENT.equals(student.getRole())) {
            throw new RuntimeException("Only Student users can fetch their personal bursary history");
        }

        return bursaryHistoryRepository.findByStudentIdOrderByYearDescMonthDesc(student.getId())
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<BursaryResponse> getBursariesForInstitution(String adminEmail, int year, int month) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.INSTITUTION_ADMIN.equals(admin.getRole())) {
            throw new RuntimeException("Only INSTITUTION_ADMIN can fetch institution bursaries");
        }

        // Ideally, we'd filter by admin.getInstitution().getId() inside the query,
        // but currently BursaryHistory doesn't directly link to Institution via DB join
        // simply.
        // Easiest is to fetch all for month/year and filter in-memory by student's
        // institution
        // Or update the repository query.

        UUID adminInstitutionId = admin.getInstitution().getId();

        return bursaryHistoryRepository.findByYearAndMonth(year, month)
                .stream()
                .filter(b -> b.getStudent() != null
                        && b.getStudent().getInstitution() != null
                        && b.getStudent().getInstitution().getId().equals(adminInstitutionId))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public BursaryResponse markBursaryAsPaid(UUID bursaryId, String adminEmail, BursaryPaymentRequest req) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.INSTITUTION_ADMIN.equals(admin.getRole())) {
            throw new RuntimeException("Only INSTITUTION_ADMIN can mark bursaries as paid");
        }

        BursaryHistory record = bursaryHistoryRepository.findById(bursaryId)
                .orElseThrow(() -> new RuntimeException("Bursary record not found"));

        // Make sure the student being paid belongs to the admin's institution
        if (record.getStudent() == null || record.getStudent().getInstitution() == null
                || !record.getStudent().getInstitution().getId().equals(admin.getInstitution().getId())) {
            throw new RuntimeException("You can only pay students in your institution");
        }

        record.setIsPaid(true);
        record.setPaymentDate(LocalDateTime.now());
        if (req != null && req.getTransactionReference() != null) {
            record.setTransactionReference(req.getTransactionReference());
        }

        return mapToResponse(bursaryHistoryRepository.save(record));
    }

    private BursaryResponse mapToResponse(BursaryHistory b) {
        return BursaryResponse.builder()
                .id(b.getId())
                .studentId(b.getStudent() != null ? b.getStudent().getId() : null)
                .studentFirstName(b.getStudent() != null ? b.getStudent().getFirstName() : null)
                .studentLastName(b.getStudent() != null ? b.getStudent().getLastName() : null)
                .year(b.getYear())
                .month(b.getMonth())
                .completedTaskCount(b.getCompletedTaskCount())
                .calculatedAmount(b.getCalculatedAmount())
                .isPaid(b.getIsPaid())
                .paymentDate(b.getPaymentDate())
                .transactionReference(b.getTransactionReference())
                .build();
    }
}
