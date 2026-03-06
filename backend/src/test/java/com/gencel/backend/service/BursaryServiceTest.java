package com.gencel.backend.service;

import com.gencel.backend.dto.BursaryPaymentRequest;
import com.gencel.backend.dto.BursaryResponse;
import com.gencel.backend.entity.BursaryHistory;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.BursaryHistoryRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BursaryServiceTest {

    @Mock
    private BursaryHistoryRepository bursaryHistoryRepository;

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BursaryService bursaryService;

    private User student;
    private User admin;
    private Institution institution;

    @BeforeEach
    void setUp() {
        institution = new Institution();
        institution.setId(UUID.randomUUID());

        student = new User();
        student.setId(UUID.randomUUID());
        student.setEmail("student@test.com");
        student.setRole(User.UserRole.STUDENT);
        student.setInstitution(institution);

        admin = new User();
        admin.setId(UUID.randomUUID());
        admin.setEmail("admin@test.com");
        admin.setRole(User.UserRole.INSTITUTION_ADMIN);
        admin.setInstitution(institution);
    }

    @Test
    void calculateBursariesForMonth_Success_ProportionalCalculation() {
        // Arrange
        int year = 2024;
        int month = 2;
        when(userRepository.findByRole(User.UserRole.STUDENT)).thenReturn(List.of(student));
        // Student completed 5 tasks
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(student.getId()), eq(Task.TaskStatus.COMPLETED), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(5L);

        when(bursaryHistoryRepository.findByStudentIdAndYearAndMonth(student.getId(), year, month))
                .thenReturn(Optional.empty()); // No existing record

        // Act
        bursaryService.calculateBursariesForMonth(year, month);

        // Assert
        ArgumentCaptor<BursaryHistory> captor = ArgumentCaptor.forClass(BursaryHistory.class);
        verify(bursaryHistoryRepository).save(captor.capture());

        BursaryHistory savedRecord = captor.getValue();
        assertEquals(student, savedRecord.getStudent());
        assertEquals(year, savedRecord.getYear());
        assertEquals(month, savedRecord.getMonth());
        assertEquals(5, savedRecord.getCompletedTaskCount());
        assertEquals(5000.0, savedRecord.getCalculatedAmount()); // 5/10 * 10000 = 5000
        assertFalse(savedRecord.getIsPaid());
    }

    @Test
    void calculateBursariesForMonth_Success_MaxCalculation() {
        // Arrange
        int year = 2024;
        int month = 2;
        when(userRepository.findByRole(User.UserRole.STUDENT)).thenReturn(List.of(student));
        // Student completed 12 tasks (more than max 10)
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(student.getId()), eq(Task.TaskStatus.COMPLETED), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(12L);

        when(bursaryHistoryRepository.findByStudentIdAndYearAndMonth(student.getId(), year, month))
                .thenReturn(Optional.empty());

        // Act
        bursaryService.calculateBursariesForMonth(year, month);

        // Assert
        ArgumentCaptor<BursaryHistory> captor = ArgumentCaptor.forClass(BursaryHistory.class);
        verify(bursaryHistoryRepository).save(captor.capture());

        BursaryHistory savedRecord = captor.getValue();
        assertEquals(12, savedRecord.getCompletedTaskCount());
        assertEquals(10000.0, savedRecord.getCalculatedAmount()); // Max capped at 10000
    }

    @Test
    void calculateBursariesForMonth_Success_UpdateExistingUnpaid() {
        // Arrange
        int year = 2024;
        int month = 2;

        BursaryHistory existingRecord = new BursaryHistory();
        existingRecord.setId(UUID.randomUUID());
        existingRecord.setStudent(student);
        existingRecord.setYear(year);
        existingRecord.setMonth(month);
        existingRecord.setCompletedTaskCount(2);
        existingRecord.setCalculatedAmount(2000.0);
        existingRecord.setIsPaid(false);

        when(userRepository.findByRole(User.UserRole.STUDENT)).thenReturn(List.of(student));
        // Student completed 8 tasks now
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                any(), any(), any(), any())).thenReturn(8L);

        when(bursaryHistoryRepository.findByStudentIdAndYearAndMonth(student.getId(), year, month))
                .thenReturn(Optional.of(existingRecord));

        // Act
        bursaryService.calculateBursariesForMonth(year, month);

        // Assert
        ArgumentCaptor<BursaryHistory> captor = ArgumentCaptor.forClass(BursaryHistory.class);
        verify(bursaryHistoryRepository).save(captor.capture());

        BursaryHistory savedRecord = captor.getValue();
        assertEquals(existingRecord.getId(), savedRecord.getId());
        assertEquals(8, savedRecord.getCompletedTaskCount());
        assertEquals(8000.0, savedRecord.getCalculatedAmount());
    }

    @Test
    void markBursaryAsPaid_Success() {
        // Arrange
        UUID bursaryId = UUID.randomUUID();
        BursaryHistory existingRecord = new BursaryHistory();
        existingRecord.setId(bursaryId);
        existingRecord.setStudent(student); // Same institution as admin
        existingRecord.setIsPaid(false);

        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.of(admin));
        when(bursaryHistoryRepository.findById(bursaryId)).thenReturn(Optional.of(existingRecord));
        when(bursaryHistoryRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        BursaryPaymentRequest req = new BursaryPaymentRequest("TRX-12345");

        // Act
        BursaryResponse response = bursaryService.markBursaryAsPaid(bursaryId, admin.getEmail(), req);

        // Assert
        assertTrue(response.getIsPaid());
        assertNotNull(response.getPaymentDate());
        assertEquals("TRX-12345", response.getTransactionReference());
    }

    @Test
    void markBursaryAsPaid_Fail_WrongInstitution() {
        // Arrange
        UUID bursaryId = UUID.randomUUID();

        Institution otherInst = new Institution();
        otherInst.setId(UUID.randomUUID());

        User otherStudent = new User();
        otherStudent.setInstitution(otherInst);

        BursaryHistory existingRecord = new BursaryHistory();
        existingRecord.setId(bursaryId);
        existingRecord.setStudent(otherStudent);

        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.of(admin));
        when(bursaryHistoryRepository.findById(bursaryId)).thenReturn(Optional.of(existingRecord));

        // Act & Assert
        assertThrows(RuntimeException.class,
                () -> bursaryService.markBursaryAsPaid(bursaryId, admin.getEmail(), new BursaryPaymentRequest()));
    }

    @Test
    void getStudentBursaryHistory_Fail_NonStudentRole() {
        // Arrange
        admin.setRole(User.UserRole.INSTITUTION_ADMIN);
        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.of(admin));

        // Act & Assert
        assertThrows(RuntimeException.class,
                () -> bursaryService.getStudentBursaryHistory(admin.getEmail()));
    }

    @Test
    void getBursariesForInstitution_Fail_NonAdminRole() {
        // Arrange
        student.setRole(User.UserRole.STUDENT);
        when(userRepository.findByEmail(student.getEmail())).thenReturn(Optional.of(student));

        // Act & Assert
        assertThrows(RuntimeException.class,
                () -> bursaryService.getBursariesForInstitution(student.getEmail(), 2024, 2));
    }

    @Test
    void markBursaryAsPaid_Fail_AdminNotFound() {
        // Arrange
        UUID bursaryId = UUID.randomUUID();
        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class,
                () -> bursaryService.markBursaryAsPaid(bursaryId, admin.getEmail(), new BursaryPaymentRequest()));
    }

    @Test
    void markBursaryAsPaid_Fail_RecordNotFound() {
        // Arrange
        UUID bursaryId = UUID.randomUUID();
        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.of(admin));
        when(bursaryHistoryRepository.findById(bursaryId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class,
                () -> bursaryService.markBursaryAsPaid(bursaryId, admin.getEmail(), new BursaryPaymentRequest()));
    }

    @Test
    void calculateBursariesForMonth_ZeroTasks_CreatesZeroAmountRecord() {
        // Arrange
        int year = 2024;
        int month = 2;
        when(userRepository.findByRole(User.UserRole.STUDENT)).thenReturn(List.of(student));
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(student.getId()), eq(Task.TaskStatus.COMPLETED), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(0L);
        when(bursaryHistoryRepository.findByStudentIdAndYearAndMonth(student.getId(), year, month))
                .thenReturn(Optional.empty());

        // Act
        bursaryService.calculateBursariesForMonth(year, month);

        // Assert
        ArgumentCaptor<BursaryHistory> captor = ArgumentCaptor.forClass(BursaryHistory.class);
        verify(bursaryHistoryRepository).save(captor.capture());

        BursaryHistory savedRecord = captor.getValue();
        assertEquals(0, savedRecord.getCompletedTaskCount());
        assertEquals(0.0, savedRecord.getCalculatedAmount());
        assertFalse(savedRecord.getIsPaid());
    }

    @Test
    void calculateBursariesForMonth_ExistingPaidRecord_NotUpdated() {
        // Arrange
        int year = 2024;
        int month = 2;

        BursaryHistory existingRecord = new BursaryHistory();
        existingRecord.setId(UUID.randomUUID());
        existingRecord.setStudent(student);
        existingRecord.setYear(year);
        existingRecord.setMonth(month);
        existingRecord.setCompletedTaskCount(5);
        existingRecord.setCalculatedAmount(5000.0);
        existingRecord.setIsPaid(true);

        when(userRepository.findByRole(User.UserRole.STUDENT)).thenReturn(List.of(student));
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(student.getId()), eq(Task.TaskStatus.COMPLETED), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(10L); // would normally give max bursary
        when(bursaryHistoryRepository.findByStudentIdAndYearAndMonth(student.getId(), year, month))
                .thenReturn(Optional.of(existingRecord));

        // Act
        bursaryService.calculateBursariesForMonth(year, month);

        // Assert
        ArgumentCaptor<BursaryHistory> captor = ArgumentCaptor.forClass(BursaryHistory.class);
        verify(bursaryHistoryRepository).save(captor.capture());

        BursaryHistory savedRecord = captor.getValue();
        assertEquals(5, savedRecord.getCompletedTaskCount());
        assertEquals(5000.0, savedRecord.getCalculatedAmount());
        assertTrue(savedRecord.getIsPaid());
    }
}
