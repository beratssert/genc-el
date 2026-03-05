package com.gencel.backend.repository;

import com.gencel.backend.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TaskRepository extends JpaRepository<Task, UUID> {
    List<Task> findByStatus(Task.TaskStatus status);

    List<Task> findByRequesterId(UUID requesterId);

    List<Task> findByVolunteerId(UUID volunteerId);

    long countByVolunteerIdAndStatusAndUpdatedAtBetween(UUID volunteerId, Task.TaskStatus status,
            java.time.LocalDateTime start, java.time.LocalDateTime end);
}
