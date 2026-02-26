package com.gencel.backend.service;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.TaskLog;
import com.gencel.backend.entity.User;
import com.gencel.backend.repository.TaskLogRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
            throw new RuntimeException("Only ELDERLY users can create tasks");
        }

        Task task = Task.builder()
                .requester(requester)
                .status(Task.TaskStatus.PENDING)
                .shoppingList(request.getShoppingList())
                .note(request.getNote())
                .isActive(true)
                .build();

        task = taskRepository.save(task);

        TaskLog log = TaskLog.builder()
                .task(task)
                .action(TaskLog.TaskLogAction.CREATED)
                .user(requester)
                .details("Shopping task created by elderly user.")
                .build();

        taskLogRepository.save(log);

        return mapToResponse(task);
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
