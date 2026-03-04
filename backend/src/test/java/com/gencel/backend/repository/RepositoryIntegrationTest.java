package com.gencel.backend.repository;

import com.gencel.backend.entity.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@TestPropertySource(locations = "classpath:application-test.properties")
public class RepositoryIntegrationTest {

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskLogRepository taskLogRepository;

    @Autowired
    private BursaryHistoryRepository bursaryHistoryRepository;

    @Test
    public void testFullFlow() {
        // 1. Create Institution
        Institution institution = Institution.builder()
                .name("Test Institution")
                .region("Test Region")
                .contactInfo("Test Contact")
                .isActive(true)
                .build();
        institution = institutionRepository.save(institution);
        assertThat(institution.getId()).isNotNull();

        // 2. Create Users
        User elderly = User.builder()
                .institution(institution)
                .role(User.UserRole.ELDERLY)
                .firstName("Test")
                .lastName("Elderly")
                .email("elderly@test.com")
                .phoneNumber("1234567890")
                .isActive(true)
                .build();
        elderly = userRepository.save(elderly);
        assertThat(elderly.getId()).isNotNull();

        User student = User.builder()
                .institution(institution)
                .role(User.UserRole.STUDENT)
                .firstName("Test")
                .lastName("Student")
                .email("student@test.com")
                .phoneNumber("0987654321")
                .iban("TR123456789")
                .isActive(true)
                .build();
        student = userRepository.save(student);
        assertThat(student.getId()).isNotNull();

        // 3. Create Task
        Task task = Task.builder()
                .requester(elderly)
                .volunteer(student)
                .status(Task.TaskStatus.PENDING)
                .shoppingList(List.of("Bread", "Milk"))
                .note("Please be quick")
                .isActive(true)
                .build();
        task = taskRepository.save(task);
        assertThat(task.getId()).isNotNull();
        assertThat(task.getShoppingList()).contains("Bread", "Milk");

        // 4. Create TaskLog
        TaskLog log = TaskLog.builder()
                .task(task)
                .action(TaskLog.TaskLogAction.CREATED)
                .user(elderly)
                .details("Created task")
                .build();
        log = taskLogRepository.save(log);
        assertThat(log.getId()).isNotNull();

        // 5. Create BursaryHistory
        BursaryHistory history = BursaryHistory.builder()
                .student(student)
                .year(2024)
                .month(1)
                .completedTaskCount(5)
                .calculatedAmount(100.0)
                .isPaid(false)
                .build();
        history = bursaryHistoryRepository.save(history);
        assertThat(history.getId()).isNotNull();

        // 6. Verify Data Retrieval
        // Institution
        Institution fetchedInstitution = institutionRepository.findById(institution.getId()).orElseThrow();
        assertThat(fetchedInstitution.getName()).isEqualTo("Test Institution");

        // Users
        User fetchedElderly = userRepository.findById(elderly.getId()).orElseThrow();
        assertThat(fetchedElderly.getEmail()).isEqualTo("elderly@test.com");
        assertThat(fetchedElderly.getRole()).isEqualTo(User.UserRole.ELDERLY);

        User fetchedStudent = userRepository.findById(student.getId()).orElseThrow();
        assertThat(fetchedStudent.getIban()).isEqualTo("TR123456789");

        // Task
        Task fetchedTask = taskRepository.findById(task.getId()).orElseThrow();
        assertThat(fetchedTask.getStatus()).isEqualTo(Task.TaskStatus.PENDING);
        assertThat(fetchedTask.getShoppingList()).hasSize(2).contains("Bread", "Milk");
        assertThat(fetchedTask.getRequester().getId()).isEqualTo(elderly.getId());

        // TaskLog
        TaskLog fetchedLog = taskLogRepository.findById(log.getId()).orElseThrow();
        assertThat(fetchedLog.getAction()).isEqualTo(TaskLog.TaskLogAction.CREATED);
        assertThat(fetchedLog.getTask().getId()).isEqualTo(task.getId());

        // BursaryHistory
        BursaryHistory fetchedHistory = bursaryHistoryRepository.findById(history.getId()).orElseThrow();
        assertThat(fetchedHistory.getCompletedTaskCount()).isEqualTo(5);
        assertThat(fetchedHistory.getStudent().getId()).isEqualTo(student.getId());
    }
}
