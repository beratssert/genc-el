package com.gencel.backend.service;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.realtime.TaskRealtimeEvent;
import org.springframework.web.multipart.MultipartFile;
import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.TaskLog;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.InvalidTaskStateException;
import com.gencel.backend.exception.TaskNotFoundException;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.repository.TaskLogRepository;
import com.gencel.backend.repository.TaskRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
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
    private final FileStorageService fileStorageService;
    private final TaskRealtimePublisher taskRealtimePublisher;

    @Autowired(required = false)
    private TaskAssignmentRedisService taskAssignmentRedisService;

    @Autowired
    private NotificationService notificationService;

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
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_CREATED, requester);

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
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        int updated = taskRepository.assignIfPending(taskId, volunteer);
        if (updated == 0) {
            throw new InvalidTaskStateException("Task is not in PENDING status");
        }

        // Reload updated task state
        task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        logAction(task, volunteer, TaskLog.TaskLogAction.ASSIGNED, "Task assigned to student volunteer.");
        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.prepareAssignment(task, volunteer);
        }
        notificationService.notifyTaskAssigned(volunteer, task,
                "Yeni görev atandı",
                "Yakınında yeni bir görev var. Kabul edilen görevi görüntüleyebilirsin.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_ASSIGNED, volunteer);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse rejectTask(UUID taskId, String email) {
        User volunteer = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!User.UserRole.STUDENT.equals(volunteer.getRole())) {
            throw new UnauthorizedActionException("Only STUDENT users can reject tasks");
        }

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (task.getVolunteer() == null || !task.getVolunteer().getId().equals(volunteer.getId())) {
            throw new UnauthorizedActionException("You are not assigned to this task");
        }

        if (!Task.TaskStatus.ASSIGNED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task is not in ASSIGNED status");
        }

        return releaseAndReassign(task, volunteer, "Student rejected the task.");
    }

    @Transactional
    public void handleAssignmentTimeout(UUID taskId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (!Task.TaskStatus.ASSIGNED.equals(task.getStatus()) || task.getVolunteer() == null) {
            return;
        }

        releaseAndReassign(task, task.getVolunteer(), "Assignment timed out.");
    }

    private TaskResponse releaseAndReassign(Task task, User releasedVolunteer, String releaseDetails) {
        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearPendingAssignment(task.getId());
        }

        logAction(task, releasedVolunteer, TaskLog.TaskLogAction.REJECTED, releaseDetails);

        var nextVolunteerOpt = taskAssignmentRedisService != null
                ? taskAssignmentRedisService.pollNextAvailableCandidate(task.getId())
                : java.util.Optional.<User>empty();
        if (nextVolunteerOpt.isPresent()) {
            User nextVolunteer = nextVolunteerOpt.get();
            task.setVolunteer(nextVolunteer);
            task.setStatus(Task.TaskStatus.ASSIGNED);
            task = taskRepository.save(task);

            if (taskAssignmentRedisService != null) {
                taskAssignmentRedisService.updatePendingAssignment(task.getId(), nextVolunteer.getId());
            }
            logAction(task, nextVolunteer, TaskLog.TaskLogAction.ASSIGNED,
                    "Task reassigned to next available student.");
            notificationService.notifyTaskAssigned(nextVolunteer, task,
                    "Yeni görev atandı",
                    "Bir önceki öğrenci görevi kabul etmedi. Görev sana atandı.");
            publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_REASSIGNED, nextVolunteer);

            return mapToResponse(task);
        }

        task.setVolunteer(null);
        task.setStatus(Task.TaskStatus.CANCELLED);
        task = taskRepository.save(task);

        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearCandidateQueue(task.getId());
        }
        logAction(task, null, TaskLog.TaskLogAction.CANCELLED,
                "No available students remaining after rejection or timeout.");
        notificationService.notifyTaskCancelled(task.getRequester(), task,
                "Görev için öğrenci bulunamadı",
                "Şu anda uygun bir öğrenci bulunamadı. Lütfen daha sonra tekrar deneyin.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_CANCELLED, releasedVolunteer);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse confirmStartTask(UUID taskId, String email, StartTaskRequest request) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (!task.getRequester().getId().equals(requester.getId())) {
            throw new UnauthorizedActionException("Only the requester can confirm the task start");
        }

        if (!Task.TaskStatus.ASSIGNED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task must be ASSIGNED before start confirmation");
        }

        task.setTotalAmountGiven(request.getTotalAmountGiven());
        task.setStartConfirmed(true);
        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.START_CONFIRMED,
                "Requester confirmed amount before shopping started.");
        notificationService.notifyTaskProgress(task.getVolunteer(), task,
                "Görev başlangıcı onaylandı",
                "Yaşlı kullanıcı verilen tutarı onayladı. Alışverişe başlayabilirsin.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_START_CONFIRMED, requester);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse startTask(UUID taskId, String email, StartTaskRequest request) {
        Task task = getAssignedTaskForStudent(taskId, email);

        if (!Task.TaskStatus.ASSIGNED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task is not in ASSIGNED status");
        }

        if (!Boolean.TRUE.equals(task.getStartConfirmed())) {
            throw new InvalidTaskStateException("Task must be confirmed by the requester before shopping starts");
        }

        if (task.getTotalAmountGiven() == null && request.getTotalAmountGiven() != null) {
            task.setTotalAmountGiven(request.getTotalAmountGiven());
        }

        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearPendingAssignment(taskId);
        }
        task.setStatus(Task.TaskStatus.IN_PROGRESS);
        task = taskRepository.save(task);

        logAction(task, task.getVolunteer(), TaskLog.TaskLogAction.SHOPPING_STARTED, "Student started shopping.");
        notificationService.notifyTaskProgress(task.getRequester(), task,
                "Alışveriş başladı",
                "Öğrenci alışverişe başladı ve görev ilerliyor.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_STARTED, task.getVolunteer());

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse deliverTask(UUID taskId, String email, DeliverTaskRequest request) {
        Task task = getAssignedTaskForStudent(taskId, email);

        if (!Task.TaskStatus.IN_PROGRESS.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task is not IN_PROGRESS");
        }

        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearPendingAssignment(taskId);
        }
        task.setStatus(Task.TaskStatus.DELIVERED);
        task.setDeliveryConfirmed(false);
        task.setChangeAmount(request.getChangeAmount());
        task.setReceiptImageUrl(request.getReceiptImageUrl());
        task = taskRepository.save(task);

        logAction(task, task.getVolunteer(), TaskLog.TaskLogAction.DELIVERED, "Student delivered the task.");
        notificationService.notifyTaskProgress(task.getRequester(), task,
                "Teslimat yapıldı",
                "Ürünler ve para üstü teslim edildi. Onay bekleniyor.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_DELIVERED, task.getVolunteer());

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse confirmDeliveryTask(UUID taskId, String email) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (!task.getRequester().getId().equals(requester.getId())) {
            throw new UnauthorizedActionException("Only the requester can confirm delivery");
        }

        if (!Task.TaskStatus.DELIVERED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task must be DELIVERED before delivery confirmation");
        }

        if (task.getChangeAmount() == null || task.getReceiptImageUrl() == null
                || task.getReceiptImageUrl().isBlank()) {
            throw new InvalidTaskStateException(
                    "Delivered task must include change amount and receipt image before confirmation");
        }

        task.setDeliveryConfirmed(true);
        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.DELIVERY_CONFIRMED, "Requester confirmed the delivered task.");
        notificationService.notifyTaskProgress(task.getVolunteer(), task,
                "Teslimat onaylandı",
                "Yaşlı kullanıcı teslimatı onayladı. Görevi kapatabilirsin.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_DELIVERY_CONFIRMED, requester);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse completeTask(UUID taskId, String email) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (!task.getRequester().getId().equals(requester.getId())) {
            throw new UnauthorizedActionException("Only the requester can complete this task");
        }

        if (!Task.TaskStatus.DELIVERED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Task must be DELIVERED before it can be completed");
        }

        if (!Boolean.TRUE.equals(task.getDeliveryConfirmed())) {
            throw new InvalidTaskStateException("Task must be confirmed by the requester before completion");
        }

        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearPendingAssignment(taskId);
            taskAssignmentRedisService.clearCandidateQueue(taskId);
        }
        task.setStatus(Task.TaskStatus.COMPLETED);
        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.COMPLETED, "Requester marked task as completed.");
        notificationService.notifyTaskProgress(task.getVolunteer(), task,
                "Görev tamamlandı",
                "Talep sahibi teslimatı onayladı. Görev başarıyla kapandı.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_COMPLETED, requester);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse cancelTask(UUID taskId, String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        // Only requester or assigned volunteer can cancel
        boolean isRequester = task.getRequester() != null && task.getRequester().getId().equals(user.getId());
        boolean isVolunteer = task.getVolunteer() != null && task.getVolunteer().getId().equals(user.getId());

        if (!isRequester && !isVolunteer) {
            throw new UnauthorizedActionException("You are not authorized to cancel this task");
        }

        if (Task.TaskStatus.DELIVERED.equals(task.getStatus()) || Task.TaskStatus.COMPLETED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Cannot cancel a completed or delivered task");
        }

        if (taskAssignmentRedisService != null) {
            taskAssignmentRedisService.clearPendingAssignment(taskId);
            taskAssignmentRedisService.clearCandidateQueue(taskId);
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
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_CANCELLED, user);

        return mapToResponse(task);
    }

    @Transactional
    public TaskResponse uploadTaskReceipt(UUID taskId, String email, MultipartFile receiptFile) {
        User requester = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

        if (!task.getRequester().getId().equals(requester.getId())) {
            throw new UnauthorizedActionException("Only the task requester can upload receipts");
        }

        if (!Task.TaskStatus.DELIVERED.equals(task.getStatus())) {
            throw new InvalidTaskStateException("Receipt can only be uploaded after task is DELIVERED");
        }

        // Delete old receipt if exists
        if (task.getReceiptImageUrl() != null && !task.getReceiptImageUrl().isEmpty()) {
            fileStorageService.deleteFile(task.getReceiptImageUrl());
        }

        // Validate and upload new receipt
        fileStorageService.validateFile(receiptFile);
        String receiptUrl = fileStorageService.uploadFile(receiptFile, taskId);

        task.setReceiptImageUrl(receiptUrl);
        task = taskRepository.save(task);

        logAction(task, requester, TaskLog.TaskLogAction.RECEIPT_UPLOADED,
                "Receipt uploaded: " + receiptFile.getOriginalFilename());

        notificationService.notifyTaskProgress(task.getVolunteer(), task,
                "Makbuz Yüklendi",
                "Yaşlı kullanıcı alışveriş makbuzunu yükledi.");
        publishTaskEvent(task, TaskRealtimeEvent.EventType.TASK_RECEIPT_UPLOADED, requester);

        return mapToResponse(task);
    }

    private void publishTaskEvent(Task task, TaskRealtimeEvent.EventType eventType, User actor) {
        taskRealtimePublisher.publishTaskEvent(task, eventType, actor);
    }

    private Task getAssignedTaskForStudent(UUID taskId, String email) {
        User volunteer = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException("Task not found"));

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
                .startConfirmed(task.getStartConfirmed())
                .deliveryConfirmed(task.getDeliveryConfirmed())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }

}
