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
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final TaskLogRepository taskLogRepository;
    private final UserRepository userRepository;

    @Transactional
    public TaskResponse createTask(CreateTaskRequest request, String email) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.ELDERLY.equals(requester.getRole())) {
            throw new UnauthorizedActionException("Only ELDERLY users can create tasks");
        }

        Task task = Task.builder()
                .requester(requester)
                .status(Task.TaskStatus.PENDING)
                .shoppingList(request.getShoppingList())
                .note(request.getNote())
                .isActive(true)
                .build();

        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.CREATED, "Shopping task created by elderly user.");

        return mapToResponse(task);
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> getPendingTasks() {
        return taskRepository.findByStatus(Task.TaskStatus.PENDING).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> getMyTasks(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Task> tasks;
        if (User.UserRole.ELDERLY.equals(user.getRole())) {
            tasks = taskRepository.findByRequesterId(user.getId());
        } else if (User.UserRole.STUDENT.equals(user.getRole())) {
            tasks = taskRepository.findByVolunteerId(user.getId());
        } else {
            tasks = List.of();
        }

        return tasks.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional
    public TaskResponse assignTask(UUID taskId, String email) {
        User volunteer = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.STUDENT.equals(volunteer.getRole())) {
            throw new UnauthorizedActionException("Only STUDENT users can accept tasks");
        }

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!Task.TaskStatus.PENDING.equals(task.getStatus())) {
            throw new RuntimeException("Task is not in PENDING status");
        }

        task.setVolunteer(volunteer);
        task.setStatus(Task.TaskStatus.ASSIGNED);
        task = taskRepository.save(task);

        logAction(task, volunteer, TaskLog.TaskLogAction.ASSIGNED, "Task assigned to student volunteer.");

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse startTask(UUID taskId, String email, StartTaskRequest request) {
        Task task = getAssignedTaskForStudent(taskId, email);

        if (!Task.TaskStatus.ASSIGNED.equals(task.getStatus())) {
            throw new RuntimeException("Task is not in ASSIGNED status");
        }

        task.setStatus(Task.TaskStatus.IN_PROGRESS);
        task.setTotalAmountGiven(request.getTotalAmountGiven());
        task = taskRepository.save(task);

        logAction(task, task.getVolunteer(), TaskLog.TaskLogAction.SHOPPING_STARTED, "Student started shopping.");

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse deliverTask(UUID taskId, String email, DeliverTaskRequest request) {
        Task task = getAssignedTaskForStudent(taskId, email);

        if (!Task.TaskStatus.IN_PROGRESS.equals(task.getStatus())) {
            throw new RuntimeException("Task is not IN_PROGRESS");
        }

        task.setStatus(Task.TaskStatus.DELIVERED);
        task.setChangeAmount(request.getChangeAmount());
        task.setReceiptImageUrl(request.getReceiptImageUrl());
        task = taskRepository.save(task);

        logAction(task, task.getVolunteer(), TaskLog.TaskLogAction.DELIVERED, "Student delivered the task.");

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse completeTask(UUID taskId, String email) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!task.getRequester().getId().equals(requester.getId())) {
            throw new UnauthorizedActionException("Only the requester can complete this task");
        }

        if (!Task.TaskStatus.DELIVERED.equals(task.getStatus())) {
            throw new RuntimeException("Task must be DELIVERED before it can be completed");
        }

        task.setStatus(Task.TaskStatus.COMPLETED);
        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.COMPLETED, "Requester marked task as completed.");

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse cancelTask(UUID taskId, String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        // Only requester or assigned volunteer can cancel
        boolean isRequester = task.getRequester() != null && task.getRequester().getId().equals(user.getId());
        boolean isVolunteer = task.getVolunteer() != null && task.getVolunteer().getId().equals(user.getId());

        if (!isRequester && !isVolunteer) {
            throw new UnauthorizedActionException("You are not authorized to cancel this task");
        }

        if (Task.TaskStatus.DELIVERED.equals(task.getStatus()) || Task.TaskStatus.COMPLETED.equals(task.getStatus())) {
            throw new RuntimeException("Cannot cancel a completed or delivered task");
        }

        if (isVolunteer) {
            // Volunteer leaves the task: return to pool
            task.setVolunteer(null);
            task.setStatus(Task.TaskStatus.PENDING);
        } else {
            // Requester cancels completely
            task.setStatus(Task.TaskStatus.CANCELLED);
        }
        task = taskRepository.save(task);

        logAction(task, user, TaskLog.TaskLogAction.CANCELLED, "Task cancelled by user.");

        return mapToResponse(task);
    }

    private Task getAssignedTaskForStudent(UUID taskId, String email) {
        User volunteer = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (task.getVolunteer() == null || !task.getVolunteer().getId().equals(volunteer.getId())) {
            throw new UnauthorizedActionException("You are not assigned to this task");
        }

        return task;
    }

    private void logAction(Task task, User user, TaskLog.TaskLogAction action, String details) {
        TaskLog log = TaskLog.builder()
                .task(task)
                .action(action)
                .user(user)
                .details(details)
                .build();
        taskLogRepository.save(log);
    }

    private TaskResponse mapToResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .requesterId(task.getRequester() != null ? task.getRequester().getId() : null)
                .volunteerId(task.getVolunteer() != null ? task.getVolunteer().getId() : null)
                .status(task.getStatus() != null ? task.getStatus().name() : null)
                .shoppingList(task.getShoppingList())
                .note(task.getNote())
                .totalAmountGiven(task.getTotalAmountGiven())
                .changeAmount(task.getChangeAmount())
                .receiptImageUrl(task.getReceiptImageUrl())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }
}
