package com.gencel.backend.service;

import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.InstitutionRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;INIT=CREATE DOMAIN IF NOT EXISTS jsonb AS text;",
    "spring.datasource.driverClassName=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.jpa.properties.hibernate.globally_quoted_identifiers=true",
    "spring.jpa.show-sql=false",
    "spring.sql.init.mode=never",
    "jwt.secret=test-secret-key-minimum-32-chars-for-hmac-sha256",
    "jwt.expiration=86400000"
})
@Testcontainers(disabledWithoutDocker = true)
@SuppressWarnings("resource")
class TaskAssignmentRedisServiceIntegrationTest {

  @Container
  static final GenericContainer<?> REDIS = new GenericContainer<>("redis:7-alpine")
      .withExposedPorts(6379);

  @DynamicPropertySource
  static void redisProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.data.redis.host", REDIS::getHost);
    registry.add("spring.data.redis.port", REDIS::getFirstMappedPort);
  }

  @Autowired
  private TaskAssignmentRedisService taskAssignmentRedisService;

  @Autowired
  private StringRedisTemplate stringRedisTemplate;

  @Autowired
  private InstitutionRepository institutionRepository;

  @Autowired
  private UserRepository userRepository;

  @Autowired
  private TaskRepository taskRepository;

  @BeforeEach
  void cleanBeforeEach() {
    taskRepository.deleteAll();
    userRepository.deleteAll();
    institutionRepository.deleteAll();
    String keys = "task_candidates:*";
    var candidateKeys = stringRedisTemplate.keys(keys);
    if (candidateKeys != null && !candidateKeys.isEmpty()) {
      stringRedisTemplate.delete(candidateKeys);
    }
    String pendingKeysPattern = "pending_assignment:*";
    var pendingKeys = stringRedisTemplate.keys(pendingKeysPattern);
    if (pendingKeys != null && !pendingKeys.isEmpty()) {
      stringRedisTemplate.delete(pendingKeys);
    }
  }

  @AfterEach
  void cleanAfterEach() {
    cleanBeforeEach();
  }

  @Test
  void prepareAssignment_enqueuesOnlyAvailableCandidates_andSetsPendingKey() {
    Institution institution = institutionRepository.save(Institution.builder()
        .name("Institution A")
        .region("Istanbul")
        .contactInfo("contact")
        .build());

    User requester = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.ELDERLY)
        .firstName("Requester")
        .lastName("User")
        .phoneNumber("+905550001111")
        .email("requester@example.com")
        .passwordHash("hash")
        .address("Requester Address")
        .latitude(41.0082)
        .longitude(28.9784)
        .build());

    User volunteer = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .firstName("Volunteer")
        .lastName("Student")
        .phoneNumber("+905550001112")
        .email("volunteer@example.com")
        .passwordHash("hash")
        .address("Volunteer Address")
        .latitude(41.0083)
        .longitude(28.9785)
        .build());

    User availableCandidate = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .firstName("Available")
        .lastName("Candidate")
        .phoneNumber("+905550001113")
        .email("available@example.com")
        .passwordHash("hash")
        .address("Available Address")
        .latitude(41.0084)
        .longitude(28.9786)
        .build());

    User busyCandidate = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .firstName("Busy")
        .lastName("Candidate")
        .phoneNumber("+905550001114")
        .email("busy@example.com")
        .passwordHash("hash")
        .address("Busy Address")
        .latitude(41.0085)
        .longitude(28.9787)
        .build());

    Task task = taskRepository.save(Task.builder()
        .requester(requester)
        .status(Task.TaskStatus.PENDING)
        .note("Need groceries")
        .build());

    taskRepository.save(Task.builder()
        .requester(requester)
        .volunteer(busyCandidate)
        .status(Task.TaskStatus.ASSIGNED)
        .note("Busy assignment")
        .build());

    taskAssignmentRedisService.prepareAssignment(task, volunteer);

    Optional<User> nextCandidate = taskAssignmentRedisService.pollNextAvailableCandidate(task.getId());
    assertThat(nextCandidate).isPresent();
    assertThat(nextCandidate.get().getId()).isEqualTo(availableCandidate.getId());

    String pendingKey = "pending_assignment:" + task.getId();
    String pendingValue = stringRedisTemplate.opsForValue().get(pendingKey);
    assertThat(pendingValue).isEqualTo(volunteer.getId().toString());
  }

  @Test
  void pollNextAvailableCandidate_skipsMissingAndBusyCandidates() {
    Institution institution = institutionRepository.save(Institution.builder()
        .name("Institution B")
        .region("Istanbul")
        .contactInfo("contact")
        .build());

    User requester = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.ELDERLY)
        .firstName("Requester")
        .lastName("Two")
        .phoneNumber("+905550001121")
        .email("requester2@example.com")
        .passwordHash("hash")
        .address("Requester Address")
        .latitude(41.0082)
        .longitude(28.9784)
        .build());

    User busyCandidate = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .firstName("Busy")
        .lastName("Candidate")
        .phoneNumber("+905550001122")
        .email("busy2@example.com")
        .passwordHash("hash")
        .address("Busy Address")
        .latitude(41.0083)
        .longitude(28.9785)
        .build());

    User availableCandidate = userRepository.save(User.builder()
        .institution(institution)
        .role(User.UserRole.STUDENT)
        .firstName("Available")
        .lastName("Candidate")
        .phoneNumber("+905550001123")
        .email("available2@example.com")
        .passwordHash("hash")
        .address("Available Address")
        .latitude(41.0084)
        .longitude(28.9786)
        .build());

    Task task = taskRepository.save(Task.builder()
        .requester(requester)
        .status(Task.TaskStatus.PENDING)
        .note("Need support")
        .build());

    taskRepository.save(Task.builder()
        .requester(requester)
        .volunteer(busyCandidate)
        .status(Task.TaskStatus.IN_PROGRESS)
        .note("Busy assignment")
        .build());

    String candidateKey = "task_candidates:" + task.getId();
    UUID missingCandidateId = UUID.randomUUID();
    stringRedisTemplate.opsForList().rightPushAll(
        candidateKey,
        missingCandidateId.toString(),
        busyCandidate.getId().toString(),
        availableCandidate.getId().toString());

    Optional<User> polled = taskAssignmentRedisService.pollNextAvailableCandidate(task.getId());

    assertThat(polled).isPresent();
    assertThat(polled.get().getId()).isEqualTo(availableCandidate.getId());
    assertThat(stringRedisTemplate.opsForList().size(candidateKey)).isZero();
  }
}
