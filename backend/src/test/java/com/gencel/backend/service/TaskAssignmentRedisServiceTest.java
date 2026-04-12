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
import java.time.LocalDateTime;

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
    private User requester;

    @BeforeEach
    void setUp() {
        volunteer = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.STUDENT)
                .institution(Institution.builder().id(UUID.randomUUID()).build())
                .latitude(39.9208)
                .longitude(32.8541)
                .build();

        candidate = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.STUDENT)
                .latitude(39.9210)
                .longitude(32.8543)
                .build();

        unavailableCandidate = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.STUDENT)
                .latitude(39.9250)
                .longitude(32.8600)
                .build();

        requester = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.ELDERLY)
                .latitude(39.9208)
                .longitude(32.8541)
                .build();

        task = Task.builder().id(UUID.randomUUID()).requester(requester).build();

        lenient().when(stringRedisTemplate.opsForList()).thenReturn(listOperations);
        lenient().when(stringRedisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void prepareAssignment_savesCandidateQueueAndPendingKey() {
        when(userRepository.findNearbyAvailableStudents(
                eq(volunteer.getInstitution().getId()),
                eq(volunteer.getId()),
                eq(requester.getLatitude()),
                eq(requester.getLongitude()),
                eq(1.0)))
                .thenReturn(List.of(candidate));

        taskAssignmentRedisService.prepareAssignment(task, volunteer);

        verify(listOperations).rightPushAll(anyString(), eq(List.of(candidate.getId().toString())));
        verify(valueOperations).set(anyString(), eq(volunteer.getId().toString()), any());
    }

    @Test
    void prepareAssignment_ordersByMonthlyCompletedCountThenDistanceAndAppliesRadius() {
        User lowCompletedNear = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.STUDENT)
                .latitude(39.9209)
                .longitude(32.8542)
                .build();

        User highCompletedNear = User.builder()
                .id(UUID.randomUUID())
                .role(User.UserRole.STUDENT)
                .latitude(39.92095)
                .longitude(32.85425)
                .build();

        when(userRepository.findNearbyAvailableStudents(
                eq(volunteer.getInstitution().getId()),
                eq(volunteer.getId()),
                eq(requester.getLatitude()),
                eq(requester.getLongitude()),
                eq(1.0)))
                .thenReturn(List.of(highCompletedNear, lowCompletedNear));
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(highCompletedNear.getId()),
                eq(Task.TaskStatus.COMPLETED),
                any(LocalDateTime.class),
                any(LocalDateTime.class))).thenReturn(5L);
        when(taskRepository.countByVolunteerIdAndStatusAndUpdatedAtBetween(
                eq(lowCompletedNear.getId()),
                eq(Task.TaskStatus.COMPLETED),
                any(LocalDateTime.class),
                any(LocalDateTime.class))).thenReturn(1L);

        taskAssignmentRedisService.prepareAssignment(task, volunteer);

        verify(listOperations).rightPushAll(anyString(), eq(List.of(
                lowCompletedNear.getId().toString(),
                highCompletedNear.getId().toString())));
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