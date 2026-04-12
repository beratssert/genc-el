package com.gencel.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateFcmTokenRequest {

  @NotBlank(message = "FCM token is required")
  @Size(max = 2048, message = "FCM token must be at most 2048 characters")
  private String fcmToken;
}