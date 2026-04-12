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
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Profile("!test")
@RequiredArgsConstructor
public class TaskAssignmentRedisService {

  private static final Duration ASSIGNMENT_TTL = Duration.ofMinutes(10);
  private static final double MATCH_RADIUS_KM = 1.0;
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

    Double requesterLat = Optional.ofNullable(task.getRequester()).map(User::getLatitude).orElse(null);
    Double requesterLon = Optional.ofNullable(task.getRequester()).map(User::getLongitude).orElse(null);

    List<String> candidateIds = students.stream()
        .filter(student -> !student.getId().equals(volunteer.getId()))
        .filter(student -> isAvailable(student.getId()))
        .filter(student -> isWithinRadius(student, requesterLat, requesterLon))
        .sorted(Comparator
            .comparingLong((User student) -> completedTasksThisMonth(student.getId()))
            .thenComparingDouble(student -> distanceOrMax(student, requesterLat, requesterLon)))
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

  private long completedTasksThisMonth(UUID studentId) {
    YearMonth currentMonth = YearMonth.now();
    LocalDateTime start = currentMonth.atDay(1).atStartOfDay();
    LocalDateTime end = currentMonth.plusMonths(1).atDay(1).atStartOfDay();
    return taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
        studentId,
        Task.TaskStatus.COMPLETED,
        start,
        end);
  }

  private boolean isWithinRadius(User student, Double requesterLat, Double requesterLon) {
    if (requesterLat == null || requesterLon == null) {
      return true;
    }
    Double studentLat = student.getLatitude();
    Double studentLon = student.getLongitude();
    if (studentLat == null || studentLon == null) {
      return false;
    }
    return haversineKm(requesterLat, requesterLon, studentLat, studentLon) <= MATCH_RADIUS_KM;
  }

  private double distanceOrMax(User student, Double requesterLat, Double requesterLon) {
    if (requesterLat == null || requesterLon == null || student.getLatitude() == null
        || student.getLongitude() == null) {
      return Double.MAX_VALUE;
    }
    return haversineKm(requesterLat, requesterLon, student.getLatitude(), student.getLongitude());
  }

  private double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    double earthRadiusKm = 6371.0;
    double dLat = Math.toRadians(lat2 - lat1);
    double dLon = Math.toRadians(lon2 - lon1);
    double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
        + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  private String candidateKey(UUID taskId) {
    return TASK_CANDIDATES_PREFIX + taskId;
  }

  private String pendingKey(UUID taskId) {
    return PENDING_ASSIGNMENT_PREFIX + taskId;
  }
}