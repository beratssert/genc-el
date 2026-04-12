package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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

        @Operation(summary = "Yakındaki Bekleyen Görevleri Listele", description = "Öğrencinin konumuna göre yakındaki PENDING görevleri listeler.")
        @GetMapping("/nearby")
        @PreAuthorize("hasRole('STUDENT')")
        public ResponseEntity<List<TaskResponse>> getNearbyPendingTasks(
                        @Parameter(hidden = true) Authentication authentication,
                        @Parameter(description = "Opsiyonel enlem") @RequestParam(required = false) Double latitude,
                        @Parameter(description = "Opsiyonel boylam") @RequestParam(required = false) Double longitude,
                        @Parameter(description = "Arama yarıçapı (km), varsayılan 5.0") @RequestParam(required = false) Double radiusKm) {
                return ResponseEntity.ok(
                                taskService.getNearbyPendingTasks(authentication.getName(), latitude, longitude,
                                                radiusKm));
        }

        @Operation(summary = "Görevlerimi Listele", description = "Kullanıcının rolüne göre kendi oluşturduğu ya da üzerine aldığı görevleri listeler.")
        @GetMapping("/my-tasks")
        public ResponseEntity<List<TaskResponse>> getMyTasks(@Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.getMyTasks(authentication.getName()));
        }

        @Operation(summary = "Aktif Görevimi Getir", description = "Öğrencinin aktif görevini (ASSIGNED veya IN_PROGRESS) döner.")
        @GetMapping("/my-active-task")
        @PreAuthorize("hasRole('STUDENT')")
        public ResponseEntity<TaskResponse> getMyActiveTask(@Parameter(hidden = true) Authentication authentication) {
                return taskService.getMyActiveTask(authentication.getName())
                                .map(ResponseEntity::ok)
                                .orElseGet(() -> ResponseEntity.noContent().build());
        }

        @Operation(summary = "Görevi Üzerine Al (Kabul Et)", description = "Bir öğrencinin bekleyen ('PENDING') bir görevi kabul etmesini sağlar. Görev durumu 'ASSIGNED' olur.")
        @PutMapping("/{taskId}/assign")
        public ResponseEntity<TaskResponse> assignTask(
                        @Parameter(description = "Kabul edilecek görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.assignTask(taskId, authentication.getName()));
        }

        @Operation(summary = "Görevi Reddet", description = "Görevi üstlenen öğrencinin görevi reddetmesini sağlar. Sistem görev aday kuyruğundan bir sonraki öğrenciyi atar (ASSIGNED) veya aday kalmadıysa görevi iptal eder (CANCELLED).")
        @PutMapping("/{taskId}/reject")
        public ResponseEntity<TaskResponse> rejectTask(
                        @Parameter(description = "Reddedilecek görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.rejectTask(taskId, authentication.getName()));
        }

        @Operation(summary = "Alışveriş Başlangıcını Onayla", description = "Yaşlı kullanıcının, öğrenci alışverişe başlamadan önce verilen para miktarını onaylamasını sağlar.")
        @PutMapping("/{taskId}/confirm-start")
        public ResponseEntity<TaskResponse> confirmStartTask(
                        @Parameter(description = "Onaylanacak görevin ID'si", required = true) @PathVariable UUID taskId,
                        @RequestBody @jakarta.validation.Valid StartTaskRequest request,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.confirmStartTask(taskId, authentication.getName(), request));
        }

        @Operation(summary = "Alışverişe Başla", description = "Öğrencinin yaşlıdan parayı alıp alışverişe başladığını bildirir. Görev durumu 'IN_PROGRESS' olur.")
        @PutMapping("/{taskId}/start")
        public ResponseEntity<TaskResponse> startTask(
                        @Parameter(description = "Başlanacak görevin ID'si", required = true) @PathVariable UUID taskId,
                        @RequestBody @jakarta.validation.Valid StartTaskRequest request,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.startTask(taskId, authentication.getName(), request));
        }

        @Operation(summary = "Teslimatı Onayla", description = "Yaşlı kullanıcının teslim edilen ürünleri, para üstünü ve fişi onaylamasını sağlar.")
        @PutMapping("/{taskId}/confirm-end")
        public ResponseEntity<TaskResponse> confirmDeliveryTask(
                        @Parameter(description = "Onaylanacak görevin ID'si", required = true) @PathVariable UUID taskId,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.confirmDeliveryTask(taskId, authentication.getName()));
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

        @Operation(summary = "Makbuz Yükle", description = "Yaşlı kullanıcının alışveriş makbuzunun fotoğrafını yüklemesini sağlar. Görev DELIVERED durumunda olmalıdır.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "200", description = "Makbuz başarıyla yüklendi", content = {
                                        @Content(mediaType = "application/json", schema = @Schema(implementation = TaskResponse.class)) }),
                        @ApiResponse(responseCode = "400", description = "Dosya geçersiz veya boyutu aşıyor", content = @Content),
                        @ApiResponse(responseCode = "403", description = "Bu işlemi yapmaya yetkiniz yok", content = @Content),
                        @ApiResponse(responseCode = "404", description = "Görev bulunamadı", content = @Content)
        })
        @PostMapping("/{taskId}/receipt/upload")
        public ResponseEntity<TaskResponse> uploadTaskReceipt(
                        @Parameter(description = "Makbuz yükleneceği görevin ID'si", required = true) @PathVariable UUID taskId,
                        @RequestPart(value = "receiptFile", required = true) MultipartFile receiptFile,
                        @Parameter(hidden = true) Authentication authentication) {
                return ResponseEntity.ok(taskService.uploadTaskReceipt(taskId, authentication.getName(), receiptFile));
        }
}
