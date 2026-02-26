package com.gencel.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import io.swagger.v3.oas.annotations.media.Schema;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TaskResponse {
    @Schema(description = "Görevin eşsiz kimliği (UUID)", example = "123e4567-e89b-12d3-a456-426614174000")
    private UUID id;

    @Schema(description = "Görevi oluşturan yaşlı/engelli kullanıcının ID'si", example = "123e4567-e89b-12d3-a456-426614174001")
    private UUID requesterId;

    @Schema(description = "Göreve atanan gönüllü öğrencinin ID'si. Henüz atanmamışsa null olabilir.", example = "123e4567-e89b-12d3-a456-426614174002", nullable = true)
    private UUID volunteerId;

    @Schema(description = "Görevin güncel durumu", example = "PENDING", allowableValues = { "PENDING", "ASSIGNED",
            "IN_PROGRESS", "DELIVERED", "COMPLETED", "CANCELLED" })
    private String status;

    @Schema(description = "Alınacak ürünlerin listesi")
    private List<String> shoppingList;

    @Schema(description = "Ekstra notlar", example = "Zili çalmayın lütfen.")
    private String note;

    @Schema(description = "Yaşlı tarafından öğrenciye teslim edilen toplam para miktarı", example = "500.0", nullable = true)
    private Double totalAmountGiven;

    @Schema(description = "Alışveriş bittikten sonra kalan para üstü", example = "25.50", nullable = true)
    private Double changeAmount;

    @Schema(description = "Alışveriş fişinin görsel URL'si", example = "https://storage.example.com/receipts/123.jpg", nullable = true)
    private String receiptImageUrl;

    @Schema(description = "Görevin oluşturulma tarihi")
    private LocalDateTime createdAt;

    @Schema(description = "Görevin son güncellenme tarihi")
    private LocalDateTime updatedAt;
}
