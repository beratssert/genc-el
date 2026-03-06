package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
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

import java.util.List;
import java.util.UUID;

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

        @Operation(summary = "Bekleyen Görevleri Listele", description = "Henüz bir öğrenci tarafından alınmamış, 'PENDING' durumundaki görevleri listeler.")
        @GetMapping("/pending")
        public ResponseEntity<List<TaskResponse>> getPendingTasks() {
                return ResponseEntity.ok(taskService.getPendingTasks());
        }

        @Operation(summary = "Görevlerimi Listele", description = "Kullanıcının rolüne göre kendi oluşturduğu ya da üzerine aldığı görevleri listeler.")
        @GetMapping("/my-tasks")
        public ResponseEntity<List<TaskResponse>> getMyTasks(@Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.getMyTasks(authentication.getName()));
        }

        @Operation(summary = "Görevi Üzerine Al (Kabul Et)", description = "Bir öğrencinin bekleyen ('PENDING') bir görevi kabul etmesini sağlar. Görev durumu 'ASSIGNED' olur.")
        @PutMapping("/{taskId}/assign")
        public ResponseEntity<TaskResponse> assignTask(
                        @Parameter(description = "Kabul edilecek görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.assignTask(taskId, authentication.getName()));
        }

        @Operation(summary = "Alışverişe Başla", description = "Öğrencinin yaşlıdan parayı alıp alışverişe başladığını bildirir. Görev durumu 'IN_PROGRESS' olur.")
        @PutMapping("/{taskId}/start")
        public ResponseEntity<TaskResponse> startTask(
                        @Parameter(description = "Başlanacak görevin ID'si", required = true) @PathVariable UUID taskId,
                        @RequestBody @jakarta.validation.Valid StartTaskRequest request,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.startTask(taskId, authentication.getName(), request));
        }

        @Operation(summary = "Alışverişi Teslim Et", description = "Öğrencinin alışverişi tamamlayıp ürünleri ve para üstünü yaşlıya teslim etmesini bildirir. Görev durumu 'DELIVERED' olur.")
        @PutMapping("/{taskId}/deliver")
        public ResponseEntity<TaskResponse> deliverTask(
                        @Parameter(description = "Teslim edilecek görevin ID'si", required = true) @PathVariable UUID taskId,
                        @RequestBody @jakarta.validation.Valid DeliverTaskRequest request,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.deliverTask(taskId, authentication.getName(), request));
        }

        @Operation(summary = "Görevi Tamamla", description = "Görev teslim edildikten sonra yaşlı kullanıcının her şeyin yolunda olduğunu onaylamasını (tamamlamasını) sağlar. Görev durumu 'COMPLETED' olur.")
        @PutMapping("/{taskId}/complete")
        public ResponseEntity<TaskResponse> completeTask(
                        @Parameter(description = "Tamamlanacak görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.completeTask(taskId, authentication.getName()));
        }

        @Operation(summary = "Görevi İptal Et", description = "Hem yaşlı (kendi oluşturduysa) hem de öğrenci (kendi üzerine aldıysa), görev 'DELIVERED' veya 'COMPLETED' olmadan önce iptal edebilir.")
        @PutMapping("/{taskId}/cancel")
        public ResponseEntity<TaskResponse> cancelTask(
                        @Parameter(description = "İptal edilecek görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.cancelTask(taskId, authentication.getName()));
        }
}
