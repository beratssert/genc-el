package com.gencel.backend.listener;

import com.gencel.backend.service.TaskService;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.listener.KeyExpirationEventMessageListener;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Component
@Profile("!test")
public class TaskAssignmentExpiryListener extends KeyExpirationEventMessageListener {

  private static final String PENDING_ASSIGNMENT_PREFIX = "pending_assignment:";

  private final TaskService taskService;

  public TaskAssignmentExpiryListener(RedisMessageListenerContainer listenerContainer, TaskService taskService) {
    super(listenerContainer);
    this.taskService = taskService;
  }

  @Override
  public void onMessage(Message message, byte[] pattern) {
    String expiredKey = new String(message.getBody(), StandardCharsets.UTF_8);
    if (!expiredKey.startsWith(PENDING_ASSIGNMENT_PREFIX)) {
      return;
    }

    String taskIdValue = expiredKey.substring(PENDING_ASSIGNMENT_PREFIX.length());
    taskService.handleAssignmentTimeout(UUID.fromString(taskIdValue));
  }
}