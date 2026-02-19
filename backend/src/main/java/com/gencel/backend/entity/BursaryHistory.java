package com.gencel.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bursary_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BursaryHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @Column(nullable = false)
    private Integer year;

    @Column(nullable = false)
    private Integer month;

    @Column(name = "completed_task_count")
    private Integer completedTaskCount;

    @Column(name = "calculated_amount")
    private Double calculatedAmount;

    @Column(name = "is_paid")
    private Boolean isPaid;

    @Column(name = "payment_date")
    private LocalDateTime paymentDate;

    @Column(name = "transaction_reference")
    private String transactionReference;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
