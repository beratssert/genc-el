package com.gencel.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TaskResponse {
    private UUID id;
    private UUID requesterId;
    private UUID volunteerId;
    private String status;
    private List<String> shoppingList;
    private String note;
    private Double totalAmountGiven;
    private Double changeAmount;
    private String receiptImageUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
