package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @PostMapping
    public ResponseEntity<TaskResponse> createTask(@RequestBody CreateTaskRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        TaskResponse response = taskService.createTask(request, email);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
