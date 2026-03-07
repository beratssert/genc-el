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
public class StartTaskRequest {
    @Schema(description = "Yaşlı tarafından öğrenciye alışveriş için verilen toplam para miktarı.", example = "500.0")
    @NotNull
    @PositiveOrZero
    private BigDecimal totalAmountGiven;
}
