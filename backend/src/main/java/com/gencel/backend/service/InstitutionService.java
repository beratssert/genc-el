package com.gencel.backend.service;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.repository.InstitutionRepository;
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

    public List<InstitutionResponse> getAllInstitutions() {
        return institutionRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public InstitutionResponse getInstitutionById(UUID id) {
        Institution institution = institutionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Institution not found with id: " + id));
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
