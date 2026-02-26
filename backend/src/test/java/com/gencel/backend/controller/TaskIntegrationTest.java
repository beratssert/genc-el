package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.service.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class TaskIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private TaskService taskService;

    @Test
    @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
    void createTask_Success() throws Exception {
        CreateTaskRequest request = CreateTaskRequest.builder()
                .shoppingList(List.of("Ekmek", "Süt"))
                .note("Zili çalmayın")
                .build();

        UUID taskId = UUID.randomUUID();
        UUID requesterId = UUID.randomUUID();

        TaskResponse mockResponse = TaskResponse.builder()
                .id(taskId)
                .requesterId(requesterId)
                .status(Task.TaskStatus.PENDING.name())
                .shoppingList(List.of("Ekmek", "Süt"))
                .note("Zili çalmayın")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(taskService.createTask(any(CreateTaskRequest.class), eq("elderly@test.com")))
                .thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.note").value("Zili çalmayın"))
                .andExpect(jsonPath("$.shoppingList[0]").value("Ekmek"))
                .andExpect(jsonPath("$.shoppingList[1]").value("Süt"))
                .andExpect(jsonPath("$.requesterId").value(requesterId.toString()));
    }

    @Test
    @WithMockUser(username = "student@test.com", roles = "STUDENT")
    void createTask_ForbiddenForStudent() throws Exception {
        CreateTaskRequest request = CreateTaskRequest.builder()
                .shoppingList(List.of("Ekmek", "Süt"))
                .note("Zili çalmayın")
                .build();

        when(taskService.createTask(any(CreateTaskRequest.class), eq("student@test.com")))
                .thenThrow(new RuntimeException("Only ELDERLY users can create tasks"));

        mockMvc.perform(post("/api/v1/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isInternalServerError());
    }
}
