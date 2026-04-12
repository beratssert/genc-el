package com.gencel.backend.service;

import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Profile("!test")
@RequiredArgsConstructor
public class TaskAssignmentRedisService {

  private static final Duration ASSIGNMENT_TTL = Duration.ofMinutes(10);
  private static final String TASK_CANDIDATES_PREFIX = "task_candidates:";
  private static final String PENDING_ASSIGNMENT_PREFIX = "pending_assignment:";

  private final StringRedisTemplate stringRedisTemplate;
  private final UserRepository userRepository;
  private final TaskRepository taskRepository;

  public void prepareAssignment(Task task, User volunteer) {
    UUID taskId = task.getId();
    clearCandidateQueue(taskId);

    UUID institutionId = Optional.ofNullable(volunteer.getInstitution())
        .map(institution -> institution.getId())
        .orElseThrow(() -> new IllegalArgumentException("Volunteer has no institution"));

    List<User> students = userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(
        institutionId, User.UserRole.STUDENT);

    List<String> candidateIds = students.stream()
        .filter(student -> !student.getId().equals(volunteer.getId()))
        .filter(student -> isAvailable(student.getId()))
        .map(student -> student.getId().toString())
        .toList();

    if (!candidateIds.isEmpty()) {
      stringRedisTemplate.opsForList().rightPushAll(candidateKey(taskId), candidateIds);
    }

    updatePendingAssignment(taskId, volunteer.getId());
  }

  public Optional<User> pollNextAvailableCandidate(UUID taskId) {
    while (true) {
      String candidateId = stringRedisTemplate.opsForList().leftPop(candidateKey(taskId));
      if (candidateId == null) {
        clearCandidateQueue(taskId);
        return Optional.empty();
      }

      UUID candidateUuid = UUID.fromString(candidateId);
      Optional<User> candidate = userRepository.findById(candidateUuid);
      if (candidate.isEmpty()) {
        continue;
      }

      if (!isAvailable(candidateUuid)) {
        continue;
      }

      return candidate;
    }
  }

  public void updatePendingAssignment(UUID taskId, UUID studentId) {
    stringRedisTemplate.opsForValue().set(pendingKey(taskId), studentId.toString(), ASSIGNMENT_TTL);
  }

  public void clearPendingAssignment(UUID taskId) {
    stringRedisTemplate.delete(pendingKey(taskId));
  }

  public void clearCandidateQueue(UUID taskId) {
    stringRedisTemplate.delete(candidateKey(taskId));
  }

  private boolean isAvailable(UUID studentId) {
    long assignedCount = taskRepository.countByVolunteerIdAndStatus(studentId, Task.TaskStatus.ASSIGNED);
    long inProgressCount = taskRepository.countByVolunteerIdAndStatus(studentId, Task.TaskStatus.IN_PROGRESS);
    return assignedCount == 0 && inProgressCount == 0;
  }

  private String candidateKey(UUID taskId) {
    return TASK_CANDIDATES_PREFIX + taskId;
  }

  private String pendingKey(UUID taskId) {
    return PENDING_ASSIGNMENT_PREFIX + taskId;
  }
}