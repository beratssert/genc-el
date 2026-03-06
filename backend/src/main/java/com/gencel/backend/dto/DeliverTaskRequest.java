package com.gencel.backend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DeliverTaskRequest {
    @Schema(description = "Alışveriş bittikten sonra kalan para üstü miktarı.", example = "25.50")
    @NotNull
    @PositiveOrZero
    private BigDecimal changeAmount;

    @Schema(description = "Alışveriş fişinin görsel URL'si (Opsiyonel)", example = "https://storage.example.com/receipts/123.jpg")
    private String receiptImageUrl;
}
