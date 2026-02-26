package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/v1/tasks")
@RequiredArgsConstructor
@Tag(name = "Görevler", description = "Alışveriş ve Görev Yönetimi API'leri")
public class TaskController {

    private final TaskService taskService;

    @Operation(summary = "Yeni Görev Oluştur", description = "Yaşlı veya engelli kullanıcının yeni bir alışveriş görevi (siparişi) oluşturmasını sağlar. Sadece 'ELDERLY' rolüne sahip kullanıcılar bu işlemi gerçekleştirebilir.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Görev başarıyla oluşturuldu", content = {
                    @Content(mediaType = "application/json", schema = @Schema(implementation = TaskResponse.class)) }),
            @ApiResponse(responseCode = "403", description = "Bu işlemi yapmaya yetkiniz yok (Örn: Öğrenci rolü)", content = @Content),
            @ApiResponse(responseCode = "400", description = "Geçersiz istek parametreleri", content = @Content)
    })
    @PostMapping
    public ResponseEntity<TaskResponse> createTask(
            @Parameter(description = "Oluşturulacak görev bilgileri", required = true) @RequestBody CreateTaskRequest request,
            @Parameter(hidden = true) Authentication authentication) {
        String email = authentication.getName();
        TaskResponse response = taskService.createTask(request, email);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
