package com.gencel.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gencel.backend.dto.CreateTaskRequest;
import com.gencel.backend.dto.DeliverTaskRequest;
import com.gencel.backend.dto.StartTaskRequest;
import com.gencel.backend.dto.TaskResponse;
import com.gencel.backend.entity.Task;
import com.gencel.backend.exception.TaskNotFoundException;
import com.gencel.backend.exception.UnauthorizedActionException;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
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

        // --- CREATE TASK ---

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
                                .thenThrow(new UnauthorizedActionException("Only ELDERLY users can create tasks"));

                mockMvc.perform(post("/api/v1/tasks")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isForbidden())
                                .andExpect(jsonPath("$.error").value("Only ELDERLY users can create tasks"));
        }

        // --- GET PENDING TASKS ---

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void getPendingTasks_Success() throws Exception {
                TaskResponse pendingTask1 = TaskResponse.builder().id(UUID.randomUUID()).status("PENDING").build();
                TaskResponse pendingTask2 = TaskResponse.builder().id(UUID.randomUUID()).status("PENDING").build();

                when(taskService.getPendingTasks()).thenReturn(List.of(pendingTask1, pendingTask2));

                mockMvc.perform(get("/api/v1/tasks/pending")
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.length()").value(2));
        }

        // --- GET MY TASKS ---

        @Test
        @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
        void getMyTasks_Success() throws Exception {
                TaskResponse myTask = TaskResponse.builder().id(UUID.randomUUID()).build();

                when(taskService.getMyTasks("elderly@test.com")).thenReturn(List.of(myTask));

                mockMvc.perform(get("/api/v1/tasks/my-tasks")
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.length()").value(1));
        }

        // --- ASSIGN TASK ---

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void assignTask_Success() throws Exception {
                UUID taskId = UUID.randomUUID();
                TaskResponse response = TaskResponse.builder().id(taskId).status("ASSIGNED").build();

                when(taskService.assignTask(taskId, "student@test.com")).thenReturn(response);

                mockMvc.perform(put("/api/v1/tasks/{taskId}/assign", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("ASSIGNED"));
        }

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void assignTask_TaskNotFound() throws Exception {
                UUID taskId = UUID.randomUUID();
                when(taskService.assignTask(taskId, "student@test.com"))
                                .thenThrow(new TaskNotFoundException("Task not found"));

                mockMvc.perform(put("/api/v1/tasks/{taskId}/assign", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isNotFound())
                                .andExpect(jsonPath("$.error").exists());
        }

        @Test
        @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
        void assignTask_Forbidden() throws Exception {
                UUID taskId = UUID.randomUUID();
                when(taskService.assignTask(taskId, "elderly@test.com"))
                                .thenThrow(new UnauthorizedActionException("Only STUDENT users can accept tasks"));

                mockMvc.perform(put("/api/v1/tasks/{taskId}/assign", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isForbidden())
                                .andExpect(jsonPath("$.error").exists());
        }

        // --- START TASK ---

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void startTask_Success() throws Exception {
                UUID taskId = UUID.randomUUID();
                StartTaskRequest request = StartTaskRequest.builder()
                                .totalAmountGiven(java.math.BigDecimal.valueOf(150.5))
                                .build();
                TaskResponse response = TaskResponse.builder().id(taskId).status("IN_PROGRESS")
                                .totalAmountGiven(java.math.BigDecimal.valueOf(150.5))
                                .build();

                when(taskService.startTask(taskId, "student@test.com", request)).thenReturn(response);

                mockMvc.perform(put("/api/v1/tasks/{taskId}/start", taskId)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
                                .andExpect(jsonPath("$.totalAmountGiven").value(150.5));
        }

        @Test
        @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
        void startTask_Unauthorized() throws Exception {
                UUID taskId = UUID.randomUUID();
                StartTaskRequest request = StartTaskRequest.builder()
                                .totalAmountGiven(java.math.BigDecimal.valueOf(150.5))
                                .build();

                when(taskService.startTask(taskId, "elderly@test.com", request))
                                .thenThrow(new UnauthorizedActionException("You are not assigned to this task"));

                mockMvc.perform(put("/api/v1/tasks/{taskId}/start", taskId)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isForbidden())
                                .andExpect(jsonPath("$.error").exists());
        }

        // --- DELIVER TASK ---

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void deliverTask_Success() throws Exception {
                UUID taskId = UUID.randomUUID();
                DeliverTaskRequest request = DeliverTaskRequest.builder()
                                .changeAmount(java.math.BigDecimal.valueOf(5.0))
                                .receiptImageUrl("http://example.com/receipt.jpg")
                                .build();
                TaskResponse response = TaskResponse.builder()
                                .id(taskId).status("DELIVERED")
                                .changeAmount(java.math.BigDecimal.valueOf(5.0))
                                .receiptImageUrl("http://example.com/receipt.jpg")
                                .build();

                when(taskService.deliverTask(taskId, "student@test.com", request)).thenReturn(response);

                mockMvc.perform(put("/api/v1/tasks/{taskId}/deliver", taskId)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("DELIVERED"))
                                .andExpect(jsonPath("$.changeAmount").value(5.0));
        }

        // --- COMPLETE TASK ---

        @Test
        @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
        void completeTask_Success() throws Exception {
                UUID taskId = UUID.randomUUID();
                TaskResponse response = TaskResponse.builder().id(taskId).status("COMPLETED").build();

                when(taskService.completeTask(taskId, "elderly@test.com")).thenReturn(response);

                mockMvc.perform(put("/api/v1/tasks/{taskId}/complete", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("COMPLETED"));
        }

        @Test
        @WithMockUser(username = "student@test.com", roles = "STUDENT")
        void completeTask_Forbidden() throws Exception {
                UUID taskId = UUID.randomUUID();
                when(taskService.completeTask(taskId, "student@test.com"))
                                .thenThrow(new UnauthorizedActionException(
                                                "Only the requester can complete this task"));

                mockMvc.perform(put("/api/v1/tasks/{taskId}/complete", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isForbidden())
                                .andExpect(jsonPath("$.error").exists());
        }

        // --- CANCEL TASK ---

        @Test
        @WithMockUser(username = "elderly@test.com", roles = "ELDERLY")
        void cancelTask_Success() throws Exception {
                UUID taskId = UUID.randomUUID();
                TaskResponse response = TaskResponse.builder().id(taskId).status("CANCELLED").build();

                when(taskService.cancelTask(taskId, "elderly@test.com")).thenReturn(response);

                mockMvc.perform(put("/api/v1/tasks/{taskId}/cancel", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("CANCELLED"));
        }

        @Test
        @WithMockUser(username = "outsider@test.com", roles = "ELDERLY")
        void cancelTask_UnauthorizedUser() throws Exception {
                UUID taskId = UUID.randomUUID();
                when(taskService.cancelTask(taskId, "outsider@test.com"))
                                .thenThrow(new UnauthorizedActionException(
                                                "You are not authorized to cancel this task"));

                mockMvc.perform(put("/api/v1/tasks/{taskId}/cancel", taskId)
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isForbidden())
                                .andExpect(jsonPath("$.error").exists());
        }
}
