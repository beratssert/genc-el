package com.gencel.backend.repository;

import com.gencel.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);

    List<User> findByInstitutionIdOrderByCreatedAtDesc(UUID institutionId);

    List<User> findByInstitutionIdAndRoleOrderByCreatedAtDesc(UUID institutionId, User.UserRole role);
}
