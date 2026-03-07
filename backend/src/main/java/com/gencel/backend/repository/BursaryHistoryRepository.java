package com.gencel.backend.repository;

import com.gencel.backend.entity.BursaryHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BursaryHistoryRepository extends JpaRepository<BursaryHistory, UUID> {
    List<BursaryHistory> findByStudentIdOrderByYearDescMonthDesc(UUID studentId);

    Optional<BursaryHistory> findByStudentIdAndYearAndMonth(UUID studentId, Integer year, Integer month);

    List<BursaryHistory> findByYearAndMonth(Integer year, Integer month);
}
