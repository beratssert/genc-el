package com.gencel.backend.service;

import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

public interface FileStorageService {

  /**
   * Uploads a file and returns the URL/path where it can be accessed.
   *
   * @param file   the file to upload
   * @param taskId the task ID to organize the upload
   * @return URL or path to the uploaded file
   */
  String uploadFile(MultipartFile file, UUID taskId);

  /**
   * Validates if the file is acceptable for upload (type, size, etc).
   *
   * @param file the file to validate
   * @throws IllegalArgumentException if validation fails
   */
  void validateFile(MultipartFile file);

  /**
   * Deletes a file by its URL or path.
   *
   * @param fileUrl the URL or path of the file to delete
   */
  void deleteFile(String fileUrl);
}
