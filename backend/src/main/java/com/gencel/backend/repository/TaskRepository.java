package com.gencel.backend.repository;

import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface TaskRepository extends JpaRepository<Task, UUID> {
    List<Task> findByStatus(Task.TaskStatus status);

    List<Task> findByRequesterId(UUID requesterId);

    List<Task> findByVolunteerId(UUID volunteerId);

    long countByVolunteerIdAndStatus(UUID volunteerId, Task.TaskStatus status);

    long countByVolunteerIdAndStatusAndUpdatedAtBetween(UUID volunteerId, Task.TaskStatus status,
            LocalDateTime start, LocalDateTime end);

    long countByVolunteer_Institution_IdAndUpdatedAtBetween(UUID institutionId,
            LocalDateTime start, LocalDateTime end);

    @Modifying
    @Query("UPDATE Task t SET t.volunteer = :volunteer, t.status = com.gencel.backend.entity.Task$TaskStatus.ASSIGNED " +
            "WHERE t.id = :taskId AND t.status = com.gencel.backend.entity.Task$TaskStatus.PENDING")
    int assignIfPending(@Param("taskId") UUID taskId, @Param("volunteer") User volunteer);
}
