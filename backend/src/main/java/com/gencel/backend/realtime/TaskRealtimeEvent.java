package com.gencel.backend.realtime;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskRealtimeEvent {

  private EventType eventType;
  private UUID taskId;
  private String status;
  private UUID requesterId;
  private UUID volunteerId;
  private UUID actorUserId;
  private UUID institutionId;
  private LocalDateTime updatedAt;

  public enum EventType {
    TASK_CREATED,
    TASK_ASSIGNED,
    TASK_REASSIGNED,
    TASK_REJECTED,
    TASK_START_CONFIRMED,
    TASK_STARTED,
    TASK_DELIVERED,
    TASK_DELIVERY_CONFIRMED,
    TASK_COMPLETED,
    TASK_CANCELLED,
    TASK_RECEIPT_UPLOADED
  }
}
