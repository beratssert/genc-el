package com.gencel.backend.service;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.entity.User;
import com.gencel.backend.exception.InstitutionNotFoundException;
import com.gencel.backend.exception.UnauthorizedActionException;
import com.gencel.backend.exception.UserNotFoundException;
import com.gencel.backend.repository.InstitutionRepository;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InstitutionService {

    private final InstitutionRepository institutionRepository;
    private final UserRepository userRepository;

    @Transactional
    public InstitutionResponse createInstitution(CreateInstitutionRequest request) {
        Institution institution = Institution.builder()
                .name(request.getName())
                .region(request.getRegion())
                .contactInfo(request.getContactInfo())
                .isActive(true)
                .build();

        institution = institutionRepository.save(institution);
        return mapToResponse(institution);
    }

    @Transactional
    public InstitutionResponse updateInstitution(UUID id, CreateInstitutionRequest request) {
        Institution institution = institutionRepository.findById(id)
                .orElseThrow(() -> new InstitutionNotFoundException("Institution not found with id: " + id));

        institution.setName(request.getName());
        institution.setRegion(request.getRegion());
        institution.setContactInfo(request.getContactInfo());

        institution = institutionRepository.save(institution);
        return mapToResponse(institution);
    }

    @Transactional
    public InstitutionResponse updateMyInstitution(String adminEmail, CreateInstitutionRequest request) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (admin.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new UnauthorizedActionException("Only INSTITUTION_ADMIN can update its own institution");
        }

        if (admin.getInstitution() == null || admin.getInstitution().getId() == null) {
            throw new IllegalArgumentException("Admin user has no institution");
        }

        UUID institutionId = admin.getInstitution().getId();
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new InstitutionNotFoundException("Institution not found with id: " + institutionId));

        institution.setName(request.getName());
        institution.setRegion(request.getRegion());
        institution.setContactInfo(request.getContactInfo());

        institution = institutionRepository.save(institution);
        return mapToResponse(institution);
    }

    @Transactional
    public void deleteMyInstitution(String adminEmail) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (admin.getRole() != User.UserRole.INSTITUTION_ADMIN) {
            throw new UnauthorizedActionException("Only INSTITUTION_ADMIN can delete its own institution");
        }

        if (admin.getInstitution() == null || admin.getInstitution().getId() == null) {
            throw new IllegalArgumentException("Admin user has no institution");
        }

        UUID institutionId = admin.getInstitution().getId();
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new InstitutionNotFoundException("Institution not found with id: " + institutionId));

        institutionRepository.delete(institution); // @SQLDelete ile soft-delete
    }

    @Transactional
    public void deleteInstitution(UUID id) {
        Institution institution = institutionRepository.findById(id)
                .orElseThrow(() -> new InstitutionNotFoundException("Institution not found with id: " + id));
        institutionRepository.delete(institution); // @SQLDelete ile soft-delete
    }

    public List<InstitutionResponse> getAllInstitutions() {
        return institutionRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public InstitutionResponse getInstitutionById(UUID id) {
        Institution institution = institutionRepository.findById(id)
                .orElseThrow(() -> new InstitutionNotFoundException("Institution not found with id: " + id));
        return mapToResponse(institution);
    }

    private InstitutionResponse mapToResponse(Institution institution) {
        return InstitutionResponse.builder()
                .id(institution.getId())
                .name(institution.getName())
                .region(institution.getRegion())
                .contactInfo(institution.getContactInfo())
                .isActive(institution.getIsActive())
                .createdAt(institution.getCreatedAt())
                .build();
    }
}
