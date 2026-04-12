package com.gencel.backend.repository;

import com.gencel.backend.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);

    // Bypasses the @SQLRestriction("is_active = true") on the User entity
    @Query(value = "SELECT * FROM users WHERE email = :email", nativeQuery = true)
    Optional<User> findByEmailIncludingDisabled(@Param("email") String email);

    List<User> findByInstitutionIdOrderByCreatedAtDesc(UUID institutionId);

    List<User> findByInstitutionIdAndRoleOrderByCreatedAtDesc(UUID institutionId, User.UserRole role);

    Optional<User> findByIdAndInstitutionId(UUID id, UUID institutionId);

    @Query("""
            SELECT u
            FROM User u
            WHERE u.institution.id = :institutionId
              AND u.role <> :excludedRole
              AND (:role IS NULL OR u.role = :role)
              AND (
            :searchPattern IS NULL
            OR LOWER(COALESCE(u.firstName, '')) LIKE :searchPattern
            OR LOWER(COALESCE(u.lastName, '')) LIKE :searchPattern
            OR LOWER(COALESCE(u.email, '')) LIKE :searchPattern
              )
            """)
    Page<User> findManagedUsers(
            @Param("institutionId") UUID institutionId,
            @Param("role") User.UserRole role,
            @Param("searchPattern") String searchPattern,
            @Param("excludedRole") User.UserRole excludedRole,
            Pageable pageable);

    @Query(value = """
            SELECT u.*
            FROM users u
            WHERE u.institution_id = :institutionId
              AND u.role = 'STUDENT'
              AND u.id <> :excludedUserId
              AND u.is_active = true
              AND (
                    :requesterLat IS NULL
                    OR :requesterLon IS NULL
                    OR u.latitude IS NULL
                    OR u.longitude IS NULL
                    OR (
                        6371 * ACOS(
                            LEAST(1, GREATEST(-1,
                                COS(RADIANS(:requesterLat)) * COS(RADIANS(u.latitude))
                                    * COS(RADIANS(u.longitude) - RADIANS(:requesterLon))
                                + SIN(RADIANS(:requesterLat)) * SIN(RADIANS(u.latitude))
                            ))
                        )
                    ) <= :radiusKm
              )
              AND NOT EXISTS (
                    SELECT 1
                    FROM tasks t
                    WHERE t.volunteer_id = u.id
                      AND t.status IN ('ASSIGNED', 'IN_PROGRESS')
              )
            ORDER BY u.created_at DESC
            """, nativeQuery = true)
    List<User> findNearbyAvailableStudents(
            @Param("institutionId") UUID institutionId,
            @Param("excludedUserId") UUID excludedUserId,
            @Param("requesterLat") Double requesterLat,
            @Param("requesterLon") Double requesterLon,
            @Param("radiusKm") double radiusKm);

    List<User> findByRole(User.UserRole role);
}
