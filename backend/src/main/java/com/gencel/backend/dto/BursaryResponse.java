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
public class BursaryResponse {
    private UUID id;
    private UUID studentId;
    private String studentFirstName;
    private String studentLastName;
    private Integer year;
    private Integer month;
    private Integer completedTaskCount;
    private Double calculatedAmount;
    private Boolean isPaid;
    private LocalDateTime paymentDate;
    private String transactionReference;
}
