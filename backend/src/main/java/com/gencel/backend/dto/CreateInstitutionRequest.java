package com.gencel.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateInstitutionRequest {

    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "Region is required")
    private String region;

    private String contactInfo;
}
