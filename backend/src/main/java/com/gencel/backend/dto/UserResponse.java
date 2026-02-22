package com.gencel.backend.dto;

import com.gencel.backend.entity.User;
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
public class UserResponse {

    private UUID id;
    private UUID institutionId;
    private User.UserRole role;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String email;
    private String address;
    private Double latitude;
    private Double longitude;
    private Boolean isActive;
    private String iban;
    private LocalDateTime createdAt;
}
