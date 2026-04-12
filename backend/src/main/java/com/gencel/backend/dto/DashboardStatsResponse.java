package com.gencel.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsResponse {

    // Student-specific stats
    private Long totalCompletedTasks;
    private Double estimatedCurrentMonthBursary;

    // Institution-specific stats
    private Long totalStudents;
    private Long totalElderlies;
    private Long totalTasksThisMonth;
}

