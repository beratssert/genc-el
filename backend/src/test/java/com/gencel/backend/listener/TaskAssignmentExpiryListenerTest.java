package com.gencel.backend.listener;

import com.gencel.backend.service.TaskService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TaskAssignmentExpiryListenerTest {

  @Mock
  private RedisMessageListenerContainer listenerContainer;

  @Mock
  private TaskService taskService;

  @InjectMocks
  private TaskAssignmentExpiryListener listener;

  @Test
  void onMessage_triggersTimeoutHandlingForPendingAssignmentKey() {
    UUID taskId = UUID.randomUUID();
    Message message = mock(Message.class);
    when(message.getBody()).thenReturn(("pending_assignment:" + taskId).getBytes(StandardCharsets.UTF_8));

    listener.onMessage(message, null);

    verify(taskService).handleAssignmentTimeout(taskId);
  }
}