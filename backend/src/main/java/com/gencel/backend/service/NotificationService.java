package com.gencel.backend.service;

import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.Map;

@Service
public class NotificationService {

  private static final URI FCM_LEGACY_ENDPOINT = URI.create("https://fcm.googleapis.com/fcm/send");

  private final HttpClient httpClient = HttpClient.newHttpClient();
  private final ObjectMapper objectMapper = new ObjectMapper();

  @Value("${firebase.server-key:}")
  private String firebaseServerKey;

  public void notifyTaskAssigned(User recipient, Task task, String title, String body) {
    send(recipient, task, title, body, Map.of("taskId", task.getId().toString(), "status", task.getStatus().name()));
  }

  public void notifyTaskCancelled(User recipient, Task task, String title, String body) {
    send(recipient, task, title, body, Map.of("taskId", task.getId().toString(), "status", task.getStatus().name()));
  }

  public void notifyTaskProgress(User recipient, Task task, String title, String body) {
    send(recipient, task, title, body, Map.of("taskId", task.getId().toString(), "status", task.getStatus().name()));
  }

  private void send(User recipient, Task task, String title, String body, Map<String, String> data) {
    if (recipient == null || recipient.getFcmToken() == null || recipient.getFcmToken().isBlank()
        || firebaseServerKey == null || firebaseServerKey.isBlank()) {
      return;
    }

    try {
      Map<String, Object> payload = new HashMap<>();
      payload.put("to", recipient.getFcmToken());
      payload.put("notification", Map.of("title", title, "body", body));
      payload.put("data", data);

      HttpRequest request = HttpRequest.newBuilder(FCM_LEGACY_ENDPOINT)
          .header("Authorization", "key=" + firebaseServerKey)
          .header("Content-Type", "application/json")
          .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)))
          .build();

      HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() >= 400) {
        throw new IllegalStateException(
            "FCM request failed with status " + response.statusCode() + ": " + response.body());
      }
    } catch (IOException exception) {
      throw new IllegalStateException("Failed to send FCM notification for task " + task.getId(), exception);
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("Failed to send FCM notification for task " + task.getId(), exception);
    }
  }
}