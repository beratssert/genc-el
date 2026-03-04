package com.gencel.backend.dto;

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
public class InstitutionResponse {
    private UUID id;
    private String name;
    private String region;
    private String contactInfo;
    private Boolean isActive;
    private LocalDateTime createdAt;
}
