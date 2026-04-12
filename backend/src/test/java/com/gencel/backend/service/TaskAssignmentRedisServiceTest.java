package com.gencel.backend.service;

import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.ListOperations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class TaskAssignmentRedisServiceTest {

  @Mock
  private StringRedisTemplate stringRedisTemplate;

  @Mock
  private UserRepository userRepository;

  @Mock
  private TaskRepository taskRepository;

  @Mock
  private ListOperations<String, String> listOperations;

  @Mock
  private ValueOperations<String, String> valueOperations;

  @InjectMocks
  private TaskAssignmentRedisService taskAssignmentRedisService;

  private Task task;
  private User volunteer;
  private User candidate;
  private User unavailableCandidate;

  @BeforeEach
  void setUp() {
    volunteer = User.builder()
        .id(UUID.randomUUID())
        .role(User.UserRole.STUDENT)
        .institution(Institution.builder().id(UUID.randomUUID()).build())
        .build();

    candidate = User.builder()
        .id(UUID.randomUUID())
        .role(User.UserRole.STUDENT)
        .build();

    unavailableCandidate = User.builder()
        .id(UUID.randomUUID())
        .role(User.UserRole.STUDENT)
        .build();

    task = Task.builder().id(UUID.randomUUID()).build();

    lenient().when(stringRedisTemplate.opsForList()).thenReturn(listOperations);
    lenient().when(stringRedisTemplate.opsForValue()).thenReturn(valueOperations);
  }

  @Test
  void prepareAssignment_savesCandidateQueueAndPendingKey() {
    when(userRepository.findByInstitutionIdAndRoleOrderByCreatedAtDesc(volunteer.getInstitution().getId(),
        User.UserRole.STUDENT))
        .thenReturn(List.of(volunteer, candidate));
    when(taskRepository.countByVolunteerIdAndStatus(candidate.getId(), Task.TaskStatus.ASSIGNED)).thenReturn(0L);
    when(taskRepository.countByVolunteerIdAndStatus(candidate.getId(), Task.TaskStatus.IN_PROGRESS)).thenReturn(0L);

    taskAssignmentRedisService.prepareAssignment(task, volunteer);

    verify(listOperations).rightPushAll(anyString(), eq(List.of(candidate.getId().toString())));
    verify(valueOperations).set(anyString(), eq(volunteer.getId().toString()), any());
  }

  @Test
  void pollNextAvailableCandidate_skipsUnavailableCandidates() {
    when(listOperations.leftPop(anyString()))
        .thenReturn(unavailableCandidate.getId().toString())
        .thenReturn(candidate.getId().toString())
        .thenReturn(null);
    when(userRepository.findById(unavailableCandidate.getId())).thenReturn(Optional.of(unavailableCandidate));
    when(userRepository.findById(candidate.getId())).thenReturn(Optional.of(candidate));
    when(taskRepository.countByVolunteerIdAndStatus(unavailableCandidate.getId(), Task.TaskStatus.ASSIGNED))
        .thenReturn(1L);
    when(taskRepository.countByVolunteerIdAndStatus(unavailableCandidate.getId(), Task.TaskStatus.IN_PROGRESS))
        .thenReturn(0L);
    when(taskRepository.countByVolunteerIdAndStatus(candidate.getId(), Task.TaskStatus.ASSIGNED)).thenReturn(0L);
    when(taskRepository.countByVolunteerIdAndStatus(candidate.getId(), Task.TaskStatus.IN_PROGRESS)).thenReturn(0L);

    Optional<User> result = taskAssignmentRedisService.pollNextAvailableCandidate(task.getId());

    assertThat(result).isPresent();
    assertThat(result.get().getId()).isEqualTo(candidate.getId());
  }
}