package com.gencel.backend.service;

import com.gencel.backend.entity.User;
import com.gencel.backend.realtime.UserLocationRealtimeEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserLocationRealtimePublisher {

  private final SimpMessagingTemplate messagingTemplate;

  public void publishLocationUpdated(User user) {
    if (user == null || user.getId() == null) {
      return;
    }

    UUID institutionId = user.getInstitution() != null ? user.getInstitution().getId() : null;

    UserLocationRealtimeEvent event = UserLocationRealtimeEvent.builder()
        .userId(user.getId())
        .institutionId(institutionId)
        .latitude(user.getLatitude())
        .longitude(user.getLongitude())
        .updatedAt(LocalDateTime.now())
        .build();

    messagingTemplate.convertAndSend("/topic/users/" + user.getId() + "/locations", event);

    if (institutionId != null) {
      messagingTemplate.convertAndSend("/topic/institutions/" + institutionId + "/locations", event);
    }
  }
}
