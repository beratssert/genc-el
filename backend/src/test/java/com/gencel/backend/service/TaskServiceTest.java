package com.gencel.backend.service;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.TaskLog;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.InvalidTaskStateException;
import com.gencel.backend.exception.TaskNotFoundException;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.realtime.TaskRealtimeEvent;
import com.gencel.backend.repository.TaskLogRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private TaskLogRepository taskLogRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private TaskAssignmentRedisService taskAssignmentRedisService;

    @Mock
    private NotificationService notificationService;

    @Mock
    private FileStorageService fileStorageService;

    @Mock
    private TaskRealtimePublisher taskRealtimePublisher;

    @InjectMocks
    private TaskService taskService;

    private User elderlyUser;
    private User studentUser;
    private Task task;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(taskService, "taskAssignmentRedisService", taskAssignmentRedisService);
        ReflectionTestUtils.setField(taskService, "notificationService", notificationService);
        ReflectionTestUtils.setField(taskService, "fileStorageService", fileStorageService);

        elderlyUser = User.builder()
                .id(UUID.randomUUID())
                .email("elderly@test.com")
                .role(User.UserRole.ELDERLY)
                .build();

        studentUser = User.builder()
                .id(UUID.randomUUID())
                .email("student@test.com")
                .role(User.UserRole.STUDENT)
                .build();

        task = Task.builder()
                .id(UUID.randomUUID())
                .requester(elderlyUser)
                .status(Task.TaskStatus.PENDING)
                .shoppingList(List.of("Bread", "Milk"))
                .note("Please be careful")
                .isActive(true)
                .build();
    }

    // --- createTask Tests ---

    @Test
    void createTask_Success() {
        CreateTaskRequest request = CreateTaskRequest.builder()
                .shoppingList(List.of("Bread", "Milk"))
                .note("Please be careful")
                .build();

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.createTask(request, elderlyUser.getEmail());

        assertNotNull(response);
        assertEquals(task.getId(), response.getId());
        assertEquals(Task.TaskStatus.PENDING.name(), response.getStatus());
        verify(taskRepository).save(any(Task.class));
        verify(taskLogRepository).save(any(TaskLog.class));
    }

    @Test
    void createTask_ThrowsException_WhenUserNotFound() {
        CreateTaskRequest request = CreateTaskRequest.builder().build();
        when(userRepository.findByEmail("notfound@test.com")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.createTask(request, "notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void createTask_ThrowsException_WhenUserIsNotElderly() {
        CreateTaskRequest request = CreateTaskRequest.builder().build();
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.createTask(request, studentUser.getEmail()));

        assertEquals("Only ELDERLY users can create tasks", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    // --- getPendingTasks Tests ---

    @Test
    void getPendingTasks_Success() {
        when(taskRepository.findByStatus(Task.TaskStatus.PENDING)).thenReturn(List.of(task));

        List<TaskResponse> responses = taskService.getPendingTasks();

        assertEquals(1, responses.size());
        assertEquals(task.getId(), responses.get(0).getId());
    }

    // --- getMyTasks Tests ---

    @Test
    void getMyTasks_Success_ElderlyUser() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findByRequesterId(elderlyUser.getId())).thenReturn(List.of(task));

        List<TaskResponse> responses = taskService.getMyTasks(elderlyUser.getEmail());

        assertEquals(1, responses.size());
        assertEquals(task.getId(), responses.get(0).getId());
    }

    @Test
    void getMyTasks_Success_StudentUser() {
        task.setVolunteer(studentUser);
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findByVolunteerId(studentUser.getId())).thenReturn(List.of(task));

        List<TaskResponse> responses = taskService.getMyTasks(studentUser.getEmail());

        assertEquals(1, responses.size());
        assertEquals(task.getId(), responses.get(0).getId());
    }

    @Test
    void getMyTasks_Success_OtherRole() {
        User otherUser = User.builder().id(UUID.randomUUID()).email("other@test.com").role(null).build();
        when(userRepository.findByEmail(otherUser.getEmail())).thenReturn(Optional.of(otherUser));

        List<TaskResponse> responses = taskService.getMyTasks(otherUser.getEmail());

        assertTrue(responses.isEmpty());
    }

    @Test
    void getMyTasks_ThrowsException_WhenUserNotFound() {
        when(userRepository.findByEmail("notfound@test.com")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.getMyTasks("notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
    }

    // --- assignTask Tests ---

    @Test
    void assignTask_Success() {
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        Task assignedTask = Task.builder()
                .id(task.getId())
                .requester(elderlyUser)
                .volunteer(studentUser)
                .status(Task.TaskStatus.ASSIGNED)
                .shoppingList(task.getShoppingList())
                .note(task.getNote())
                .isActive(true)
                .build();
        when(taskRepository.findById(task.getId()))
                .thenReturn(Optional.of(task))
                .thenReturn(Optional.of(assignedTask));
        when(taskRepository.assignIfPending(task.getId(), studentUser)).thenReturn(1);

        TaskResponse response = taskService.assignTask(task.getId(), studentUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.ASSIGNED.name(), response.getStatus());
        assertEquals(studentUser.getId(), response.getVolunteerId());
        verify(taskAssignmentRedisService).prepareAssignment(any(Task.class), eq(studentUser));
        verify(taskLogRepository).save(any(TaskLog.class));
        verify(taskRealtimePublisher).publishTaskEvent(any(Task.class), eq(TaskRealtimeEvent.EventType.TASK_ASSIGNED),
                eq(studentUser));
    }

    @Test
    void assignTask_ThrowsException_WhenUserNotFound() {
        when(userRepository.findByEmail("notfound@test.com")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.assignTask(task.getId(), "notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenUserIsNotStudent() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.assignTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Only STUDENT users can accept tasks", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenTaskNotFound() {
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.assignTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenTaskNotPending() {
        task.setStatus(Task.TaskStatus.ASSIGNED);
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.assignIfPending(task.getId(), studentUser)).thenReturn(0);

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.assignTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task is not in PENDING status", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    // --- rejectTask Tests ---

    @Test
    void rejectTask_Success() {
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);
        User nextStudent = User.builder()
                .id(UUID.randomUUID())
                .email("next@test.com")
                .role(User.UserRole.STUDENT)
                .build();

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskAssignmentRedisService.pollNextAvailableCandidate(task.getId())).thenReturn(Optional.of(nextStudent));

        TaskResponse response = taskService.rejectTask(task.getId(), studentUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.ASSIGNED.name(), response.getStatus());
        assertEquals(nextStudent.getId(), response.getVolunteerId());
        verify(taskRepository, atLeastOnce()).save(any(Task.class));
        verify(taskAssignmentRedisService).clearPendingAssignment(task.getId());
        verify(taskAssignmentRedisService).updatePendingAssignment(task.getId(), nextStudent.getId());
        verify(taskLogRepository, atLeast(2)).save(any(TaskLog.class));
    }

    @Test
    void rejectTask_ThrowsException_WhenUserNotFound() {
        when(userRepository.findByEmail("notfound@test.com")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.rejectTask(task.getId(), "notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void rejectTask_ThrowsException_WhenUserIsNotStudent() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.rejectTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Only STUDENT users can reject tasks", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void rejectTask_ThrowsException_WhenTaskNotFound() {
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.rejectTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task not found", exception.getMessage());
    }

    @Test
    void rejectTask_ThrowsException_WhenTaskIsNotAssigned() {
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.PENDING);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.rejectTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task is not in ASSIGNED status", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void rejectTask_ThrowsException_WhenTaskAssignedToAnotherStudent() {
        User anotherStudent = User.builder()
                .id(UUID.randomUUID())
                .email("another@test.com")
                .role(User.UserRole.STUDENT)
                .build();
        task.setVolunteer(anotherStudent);
        task.setStatus(Task.TaskStatus.ASSIGNED);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.rejectTask(task.getId(), studentUser.getEmail()));

        assertEquals("You are not assigned to this task", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void handleAssignmentTimeout_ReassignsToNextAvailableStudent() {
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);
        User nextStudent = User.builder()
                .id(UUID.randomUUID())
                .email("next@test.com")
                .role(User.UserRole.STUDENT)
                .build();

        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskAssignmentRedisService.pollNextAvailableCandidate(task.getId())).thenReturn(Optional.of(nextStudent));

        taskService.handleAssignmentTimeout(task.getId());

        assertEquals(Task.TaskStatus.ASSIGNED, task.getStatus());
        assertEquals(nextStudent, task.getVolunteer());
        verify(taskAssignmentRedisService).updatePendingAssignment(task.getId(), nextStudent.getId());
        verify(taskLogRepository, atLeastOnce()).save(any(TaskLog.class));
    }

    @Test
    void handleAssignmentTimeout_CancelsWhenNoCandidateLeft() {
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);

        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskAssignmentRedisService.pollNextAvailableCandidate(task.getId())).thenReturn(Optional.empty());

        taskService.handleAssignmentTimeout(task.getId());

        assertEquals(Task.TaskStatus.CANCELLED, task.getStatus());
        assertNull(task.getVolunteer());
        verify(taskAssignmentRedisService).clearCandidateQueue(task.getId());
        verify(taskLogRepository, atLeastOnce()).save(any(TaskLog.class));
    }

    // --- confirmStartTask Tests ---

    @Test
    void confirmStartTask_Success() {
        StartTaskRequest request = StartTaskRequest.builder()
                .totalAmountGiven(java.math.BigDecimal.valueOf(100.0))
                .build();

        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.confirmStartTask(task.getId(), elderlyUser.getEmail(), request);

        assertNotNull(response);
        assertEquals(Boolean.TRUE, response.getStartConfirmed());
        assertEquals(java.math.BigDecimal.valueOf(100.0), response.getTotalAmountGiven());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
    }

    @Test
    void confirmStartTask_ThrowsException_WhenNotRequester() {
        StartTaskRequest request = StartTaskRequest.builder().build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.confirmStartTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Only the requester can confirm the task start", exception.getMessage());
    }

    // --- startTask Tests ---

    @Test
    void startTask_Success() {
        StartTaskRequest request = StartTaskRequest.builder()
                .totalAmountGiven(java.math.BigDecimal.valueOf(100.0))
                .build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);
        task.setStartConfirmed(true);
        task.setTotalAmountGiven(java.math.BigDecimal.valueOf(100.0));

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.startTask(task.getId(), studentUser.getEmail(), request);

        assertNotNull(response);
        assertEquals(Task.TaskStatus.IN_PROGRESS.name(), response.getStatus());
        assertEquals(java.math.BigDecimal.valueOf(100.0), response.getTotalAmountGiven());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
        verify(taskRealtimePublisher).publishTaskEvent(any(Task.class), eq(TaskRealtimeEvent.EventType.TASK_STARTED),
                eq(studentUser));
    }

    @Test
    void startTask_ThrowsException_WhenNotAssignedToVolunteer() {
        StartTaskRequest request = StartTaskRequest.builder().build();
        User anotherStudent = User.builder().id(UUID.randomUUID()).email("another@test.com").role(User.UserRole.STUDENT)
                .build();
        task.setVolunteer(anotherStudent);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.startTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("You are not assigned to this task", exception.getMessage());
    }

    @Test
    void startTask_ThrowsException_WhenTaskNotAssigned() {
        StartTaskRequest request = StartTaskRequest.builder()
                .totalAmountGiven(java.math.BigDecimal.valueOf(100.0))
                .build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.PENDING); // Not ASSIGNED

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.startTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task is not in ASSIGNED status", exception.getMessage());
    }

    @Test
    void startTask_ThrowsTaskNotFound_WhenTaskDoesNotExist() {
        StartTaskRequest request = StartTaskRequest.builder()
                .totalAmountGiven(java.math.BigDecimal.valueOf(100.0))
                .build();

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.startTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task not found", exception.getMessage());
    }

    // --- deliverTask Tests ---

    @Test
    void deliverTask_Success() {
        DeliverTaskRequest request = DeliverTaskRequest.builder()
                .changeAmount(java.math.BigDecimal.valueOf(10.0))
                .receiptImageUrl("http://example.com/receipt.jpg")
                .build();

        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.IN_PROGRESS);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.deliverTask(task.getId(), studentUser.getEmail(), request);

        assertNotNull(response);
        assertEquals(Task.TaskStatus.DELIVERED.name(), response.getStatus());
        assertEquals(java.math.BigDecimal.valueOf(10.0), response.getChangeAmount());
        assertEquals("http://example.com/receipt.jpg", response.getReceiptImageUrl());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
        verify(taskRealtimePublisher).publishTaskEvent(any(Task.class), eq(TaskRealtimeEvent.EventType.TASK_DELIVERED),
                eq(studentUser));
    }

    @Test
    void deliverTask_ThrowsException_WhenTaskNotInProgress() {
        DeliverTaskRequest request = DeliverTaskRequest.builder().build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED); // Not IN_PROGRESS

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.deliverTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task is not IN_PROGRESS", exception.getMessage());
    }

    @Test
    void deliverTask_ThrowsTaskNotFound_WhenTaskDoesNotExist() {
        DeliverTaskRequest request = DeliverTaskRequest.builder()
                .changeAmount(java.math.BigDecimal.valueOf(10.0))
                .build();

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.deliverTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task not found", exception.getMessage());
    }

    // --- completeTask Tests ---

    @Test
    void completeTask_Success() {
        task.setStatus(Task.TaskStatus.DELIVERED);
        task.setDeliveryConfirmed(true);

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.completeTask(task.getId(), elderlyUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.COMPLETED.name(), response.getStatus());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
        verify(taskRealtimePublisher)
                .publishTaskEvent(any(Task.class), eq(TaskRealtimeEvent.EventType.TASK_COMPLETED), eq(elderlyUser));
    }

    @Test
    void completeTask_ThrowsException_WhenNotRequester() {
        User anotherElderly = User.builder().id(UUID.randomUUID()).email("anotherelderly@test.com")
                .role(User.UserRole.ELDERLY).build();
        when(userRepository.findByEmail(anotherElderly.getEmail())).thenReturn(Optional.of(anotherElderly));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.completeTask(task.getId(), anotherElderly.getEmail()));

        assertEquals("Only the requester can complete this task", exception.getMessage());
    }

    @Test
    void completeTask_ThrowsException_WhenNotDelivered() {
        task.setStatus(Task.TaskStatus.IN_PROGRESS);
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.completeTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Task must be DELIVERED before it can be completed", exception.getMessage());
    }

    @Test
    void completeTask_ThrowsTaskNotFound_WhenTaskDoesNotExist() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.completeTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Task not found", exception.getMessage());
    }

    // --- cancelTask Tests ---

    @Test
    void cancelTask_Success_ByRequester() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.cancelTask(task.getId(), elderlyUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.CANCELLED.name(), response.getStatus());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
    }

    @Test
    void cancelTask_Success_ByVolunteer() {
        task.setVolunteer(studentUser);
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.cancelTask(task.getId(), studentUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.PENDING.name(), response.getStatus());
        assertNull(response.getVolunteerId());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
    }

    @Test
    void cancelTask_ThrowsException_WhenUnauthorizedUser() {
        User outsider = User.builder().id(UUID.randomUUID()).email("outsider@test.com").build();
        task.setVolunteer(studentUser);

        when(userRepository.findByEmail(outsider.getEmail())).thenReturn(Optional.of(outsider));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.cancelTask(task.getId(), outsider.getEmail()));

        assertEquals("You are not authorized to cancel this task", exception.getMessage());
    }

    @Test
    void cancelTask_ThrowsException_WhenTaskAlreadyDelivered() {
        task.setStatus(Task.TaskStatus.DELIVERED);
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.cancelTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Cannot cancel a completed or delivered task", exception.getMessage());
    }

    @Test
    void cancelTask_ThrowsTaskNotFound_WhenTaskDoesNotExist() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.cancelTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Task not found", exception.getMessage());
    }

    // --- uploadTaskReceipt Tests ---

    @Test
    void uploadTaskReceipt_Success() {
        task.setStatus(Task.TaskStatus.DELIVERED);
        task.setVolunteer(studentUser);

        MultipartFile mockFile = mock(MultipartFile.class);
        when(mockFile.getOriginalFilename()).thenReturn("receipt.jpg");

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(fileStorageService.uploadFile(mockFile, task.getId()))
                .thenReturn("/uploads/receipts/" + task.getId() + "/receipt.jpg");
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.uploadTaskReceipt(task.getId(), elderlyUser.getEmail(), mockFile);

        assertNotNull(response);
        assertEquals(Task.TaskStatus.DELIVERED.name(), response.getStatus());
        verify(fileStorageService).validateFile(mockFile);
        verify(fileStorageService).uploadFile(mockFile, task.getId());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
        verify(notificationService).notifyTaskProgress(eq(studentUser), eq(task), any(), any());
    }

    @Test
    void uploadTaskReceipt_ThrowsException_WhenNotRequester() {
        task.setStatus(Task.TaskStatus.DELIVERED);
        User anotherElderly = User.builder().id(UUID.randomUUID()).email("anotherelderly@test.com")
                .role(User.UserRole.ELDERLY).build();

        MultipartFile mockFile = mock(MultipartFile.class);

        when(userRepository.findByEmail(anotherElderly.getEmail())).thenReturn(Optional.of(anotherElderly));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class,
                () -> taskService.uploadTaskReceipt(task.getId(), anotherElderly.getEmail(), mockFile));

        assertEquals("Only the task requester can upload receipts", exception.getMessage());
    }

    @Test
    void uploadTaskReceipt_ThrowsException_WhenTaskNotDelivered() {
        task.setStatus(Task.TaskStatus.IN_PROGRESS);

        MultipartFile mockFile = mock(MultipartFile.class);

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        InvalidTaskStateException exception = assertThrows(InvalidTaskStateException.class,
                () -> taskService.uploadTaskReceipt(task.getId(), elderlyUser.getEmail(), mockFile));

        assertEquals("Receipt can only be uploaded after task is DELIVERED", exception.getMessage());
    }

    @Test
    void uploadTaskReceipt_ThrowsTaskNotFound_WhenTaskDoesNotExist() {
        MultipartFile mockFile = mock(MultipartFile.class);

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        TaskNotFoundException exception = assertThrows(TaskNotFoundException.class,
                () -> taskService.uploadTaskReceipt(task.getId(), elderlyUser.getEmail(), mockFile));

        assertEquals("Task not found", exception.getMessage());
    }
}
