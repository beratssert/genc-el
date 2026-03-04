package com.gencel.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import io.swagger.v3.oas.annotations.media.Schema;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DeliverTaskRequest {
    @Schema(description = "Alışveriş bittikten sonra kalan para üstü miktarı.", required = true, example = "25.50")
    private Double changeAmount;

    @Schema(description = "Alışveriş fişinin görsel URL'si (Opsiyonel)", example = "https://storage.example.com/receipts/123.jpg")
    private String receiptImageUrl;
}
