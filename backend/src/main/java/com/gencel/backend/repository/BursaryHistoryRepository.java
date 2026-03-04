package com.gencel.backend.repository;

import com.gencel.backend.entity.BursaryHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface BursaryHistoryRepository extends JpaRepository<BursaryHistory, UUID> {
}
