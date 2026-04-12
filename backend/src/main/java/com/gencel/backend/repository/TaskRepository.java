package com.gencel.backend.repository;

import com.gencel.backend.entity.Task;
import com.gencel.backend.entity.User;
import org.springframework.data.jpa.repository.EntityGraph;
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
        @EntityGraph(attributePaths = { "requester", "volunteer" })
        List<Task> findByStatus(Task.TaskStatus status);

        @EntityGraph(attributePaths = { "requester", "volunteer" })
        List<Task> findByRequesterId(UUID requesterId);

        @EntityGraph(attributePaths = { "requester", "volunteer" })
        List<Task> findByVolunteerId(UUID volunteerId);

        @Query(value = """
                        SELECT t.*
                        FROM tasks t
                        JOIN users r ON r.id = t.requester_id
                        WHERE t.status = 'PENDING'
                          AND t.is_active = true
                          AND r.is_active = true
                          AND r.institution_id = :institutionId
                          AND (
                                        :lat IS NULL
                                        OR :lon IS NULL
                                        OR r.latitude IS NULL
                                        OR r.longitude IS NULL
                                        OR (
                                                6371 * ACOS(
                                                        LEAST(1, GREATEST(-1,
                                                                COS(RADIANS(:lat)) * COS(RADIANS(r.latitude))
                                                                        * COS(RADIANS(r.longitude) - RADIANS(:lon))
                                                                + SIN(RADIANS(:lat)) * SIN(RADIANS(r.latitude))
                                                        ))
                                                )
                                        ) <= :radiusKm
                          )
                        ORDER BY t.created_at DESC
                        """, nativeQuery = true)
        List<Task> findNearbyPendingTasks(
                        @Param("institutionId") UUID institutionId,
                        @Param("lat") Double lat,
                        @Param("lon") Double lon,
                        @Param("radiusKm") double radiusKm);

        long countByVolunteerIdAndStatus(UUID volunteerId, Task.TaskStatus status);

        long countByVolunteerIdAndStatusAndUpdatedAtBetween(UUID volunteerId, Task.TaskStatus status,
                        LocalDateTime start, LocalDateTime end);

        long countByVolunteer_Institution_IdAndUpdatedAtBetween(UUID institutionId,
                        LocalDateTime start, LocalDateTime end);

        @Modifying
        @Query("UPDATE Task t SET t.volunteer = :volunteer, t.status = com.gencel.backend.entity.Task$TaskStatus.ASSIGNED "
                        +
                        "WHERE t.id = :taskId AND t.status = com.gencel.backend.entity.Task$TaskStatus.PENDING")
        int assignIfPending(@Param("taskId") UUID taskId, @Param("volunteer") User volunteer);
}
