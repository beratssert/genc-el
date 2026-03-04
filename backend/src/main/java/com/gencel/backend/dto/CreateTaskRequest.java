package com.gencel.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CreateTaskRequest {
    @Schema(description = "Alınacak ürünlerin listesi. Örn: ['1 Ekmek', '1 Süt']", required = true, example = "[\"1 Ekmek\", \"1 Süt\"]")
    private List<String> shoppingList;

    @Schema(description = "Gönüllü öğrenciye iletilecek ekstra notlar veya yönergeler. Örn: 'Zili çalmayın lütfen.'", example = "Zili çalmayın lütfen.")
    private String note;
}
