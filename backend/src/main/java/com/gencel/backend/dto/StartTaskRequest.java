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
public class StartTaskRequest {
    @Schema(description = "Yaşlı tarafından öğrenciye alışveriş için verilen toplam para miktarı.", required = true, example = "500.0")
    private Double totalAmountGiven;
}
