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
public class UserLocationRealtimeEvent {
  private UUID userId;
  private UUID institutionId;
  private Double latitude;
  private Double longitude;
  private LocalDateTime updatedAt;
}
