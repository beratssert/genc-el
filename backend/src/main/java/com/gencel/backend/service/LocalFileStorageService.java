package com.gencel.backend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Slf4j
@Service
@ConditionalOnProperty(name = "app.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalFileStorageService implements FileStorageService {

  @Value("${app.storage.local.path:/uploads}")
  private String basePath;

  @Value("${app.storage.max-file-size:5242880}") // 5MB default
  private long maxFileSize;

  private static final String[] ALLOWED_MIME_TYPES = { "image/jpeg", "image/png" };
  private static final String[] ALLOWED_EXTENSIONS = { ".jpg", ".jpeg", ".png" };
  private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");

  @Override
  public String uploadFile(MultipartFile file, UUID taskId) {
    validateFile(file);

    try {
      // Create directory structure: /uploads/receipts/{taskId}/
      Path taskDir = Paths.get(basePath, "receipts", taskId.toString());
      Files.createDirectories(taskDir);

      // Generate unique filename: {timestamp}_{originalName}
      String timestamp = LocalDateTime.now().format(TIMESTAMP_FORMAT);
      String originalFileName = file.getOriginalFilename();
      String extension = getFileExtension(originalFileName);
      String fileName = timestamp + "_" + UUID.randomUUID().toString().substring(0, 8) + extension;

      Path filePath = taskDir.resolve(fileName);

      // Save file
      file.transferTo(filePath.toFile());
      log.info("File uploaded successfully: {}", filePath);

      // Return relative URL path for storage: receipts/{taskId}/{fileName}
      return "/uploads/receipts/" + taskId + "/" + fileName;

    } catch (IOException e) {
      log.error("Error uploading file for task {}: {}", taskId, e.getMessage());
      throw new RuntimeException("Failed to upload file: " + e.getMessage(), e);
    }
  }

  @Override
  public void validateFile(MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new IllegalArgumentException("File cannot be empty");
    }

    // Check file size
    if (file.getSize() > maxFileSize) {
      throw new IllegalArgumentException(
          "File size exceeds maximum allowed size of " + (maxFileSize / 1024 / 1024) + "MB");
    }

    // Check MIME type
    String mimeType = file.getContentType();
    if (mimeType == null || !isSupportedMimeType(mimeType)) {
      throw new IllegalArgumentException("File type not allowed. Supported types: JPEG, PNG");
    }

    // Check file extension
    String fileName = file.getOriginalFilename();
    if (fileName == null || !isSupportedExtension(fileName)) {
      throw new IllegalArgumentException("File extension not allowed. Supported: .jpg, .jpeg, .png");
    }
  }

  @Override
  public void deleteFile(String fileUrl) {
    try {
      // Convert URL path to file system path
      // e.g., /uploads/receipts/{taskId}/{fileName} →
      // {basePath}/receipts/{taskId}/{fileName}
      String relativePath = fileUrl.startsWith("/uploads/") ? fileUrl.substring(1) : fileUrl;
      Path filePath = Paths.get(basePath).getParent().resolve(relativePath);

      if (Files.exists(filePath)) {
        Files.delete(filePath);
        log.info("File deleted successfully: {}", filePath);
      } else {
        log.warn("File not found for deletion: {}", filePath);
      }
    } catch (IOException e) {
      log.error("Error deleting file {}: {}", fileUrl, e.getMessage());
      // Don't throw - allow task deletion to proceed even if file cleanup fails
    }
  }

  private boolean isSupportedMimeType(String mimeType) {
    for (String allowed : ALLOWED_MIME_TYPES) {
      if (mimeType.equalsIgnoreCase(allowed)) {
        return true;
      }
    }
    return false;
  }

  private boolean isSupportedExtension(String fileName) {
    String lowerName = fileName.toLowerCase();
    for (String ext : ALLOWED_EXTENSIONS) {
      if (lowerName.endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  private String getFileExtension(String fileName) {
    if (fileName == null || fileName.lastIndexOf('.') == -1) {
      return ".jpg";
    }
    return fileName.substring(fileName.lastIndexOf('.'));
  }
}
