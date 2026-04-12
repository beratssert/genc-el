package com.gencel.backend.service;

import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.gencel.backend.realtime.TaskRealtimeEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TaskRealtimePublisher {

  private final SimpMessagingTemplate messagingTemplate;

  public void publishTaskEvent(Task task, TaskRealtimeEvent.EventType eventType, User actor) {
    if (task == null) {
      return;
    }

    UUID requesterId = task.getRequester() != null ? task.getRequester().getId() : null;
    UUID volunteerId = task.getVolunteer() != null ? task.getVolunteer().getId() : null;
    UUID actorId = actor != null ? actor.getId() : null;
    UUID institutionId = task.getRequester() != null && task.getRequester().getInstitution() != null
        ? task.getRequester().getInstitution().getId()
        : null;

    TaskRealtimeEvent event = TaskRealtimeEvent.builder()
        .eventType(eventType)
        .taskId(task.getId())
        .status(task.getStatus() != null ? task.getStatus().name() : null)
        .requesterId(requesterId)
        .volunteerId(volunteerId)
        .actorUserId(actorId)
        .institutionId(institutionId)
        .updatedAt(task.getUpdatedAt())
        .build();

    if (institutionId != null) {
      messagingTemplate.convertAndSend("/topic/institutions/" + institutionId + "/tasks", event);
    }

    if (requesterId != null) {
      messagingTemplate.convertAndSend("/topic/users/" + requesterId + "/tasks", event);
    }

    if (volunteerId != null && !volunteerId.equals(requesterId)) {
      messagingTemplate.convertAndSend("/topic/users/" + volunteerId + "/tasks", event);
    }
  }
}
