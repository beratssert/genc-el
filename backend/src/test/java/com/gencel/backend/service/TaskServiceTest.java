package com.gencel.backend.service;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.TaskLog;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.repository.TaskLogRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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

    @InjectMocks
    private TaskService taskService;

    private User elderlyUser;
    private User studentUser;
    private Task task;

    @BeforeEach
    void setUp() {
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

        RuntimeException exception = assertThrows(RuntimeException.class, () ->
                taskService.getMyTasks("notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
    }

    // --- assignTask Tests ---

    @Test
    void assignTask_Success() {
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.assignTask(task.getId(), studentUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.ASSIGNED.name(), response.getStatus());
        assertEquals(studentUser.getId(), response.getVolunteerId());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
    }

    @Test
    void assignTask_ThrowsException_WhenUserNotFound() {
        when(userRepository.findByEmail("notfound@test.com")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class, () ->
                taskService.assignTask(task.getId(), "notfound@test.com"));

        assertEquals("User not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenUserIsNotStudent() {
        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));

        UnauthorizedActionException exception = assertThrows(UnauthorizedActionException.class, () ->
                taskService.assignTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Only STUDENT users can accept tasks", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenTaskNotFound() {
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(RuntimeException.class, () ->
                taskService.assignTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task not found", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void assignTask_ThrowsException_WhenTaskNotPending() {
        task.setStatus(Task.TaskStatus.ASSIGNED);
        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.assignTask(task.getId(), studentUser.getEmail()));

        assertEquals("Task is not in PENDING status", exception.getMessage());
        verify(taskRepository, never()).save(any(Task.class));
    }

    // --- startTask Tests ---

    @Test
    void startTask_Success() {
        StartTaskRequest request = StartTaskRequest.builder()
                .totalAmountGiven(java.math.BigDecimal.valueOf(100.0))
                .build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED);

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.startTask(task.getId(), studentUser.getEmail(), request);

        assertNotNull(response);
        assertEquals(Task.TaskStatus.IN_PROGRESS.name(), response.getStatus());
        assertEquals(java.math.BigDecimal.valueOf(100.0), response.getTotalAmountGiven());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
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

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.startTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task is not in ASSIGNED status", exception.getMessage());
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
    }

    @Test
    void deliverTask_ThrowsException_WhenTaskNotInProgress() {
        DeliverTaskRequest request = DeliverTaskRequest.builder().build();
        task.setVolunteer(studentUser);
        task.setStatus(Task.TaskStatus.ASSIGNED); // Not IN_PROGRESS

        when(userRepository.findByEmail(studentUser.getEmail())).thenReturn(Optional.of(studentUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.deliverTask(task.getId(), studentUser.getEmail(), request));

        assertEquals("Task is not IN_PROGRESS", exception.getMessage());
    }

    // --- completeTask Tests ---

    @Test
    void completeTask_Success() {
        task.setStatus(Task.TaskStatus.DELIVERED);

        when(userRepository.findByEmail(elderlyUser.getEmail())).thenReturn(Optional.of(elderlyUser));
        when(taskRepository.findById(task.getId())).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        TaskResponse response = taskService.completeTask(task.getId(), elderlyUser.getEmail());

        assertNotNull(response);
        assertEquals(Task.TaskStatus.COMPLETED.name(), response.getStatus());
        verify(taskRepository).save(task);
        verify(taskLogRepository).save(any(TaskLog.class));
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

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.completeTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Task must be DELIVERED before it can be completed", exception.getMessage());
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

        RuntimeException exception = assertThrows(RuntimeException.class,
                () -> taskService.cancelTask(task.getId(), elderlyUser.getEmail()));

        assertEquals("Cannot cancel a completed or delivered task", exception.getMessage());
    }
}
