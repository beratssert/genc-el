package com.gencel.backend.controller;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.service.InstitutionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/institution")
@RequiredArgsConstructor
public class InstitutionController {

    private final InstitutionService institutionService;

    @PostMapping
    // @PreAuthorize("hasRole('SYSTEM_ADMIN')") // Just an example, assuming only higher admins can create institutions
    public ResponseEntity<InstitutionResponse> createInstitution(@Valid @RequestBody CreateInstitutionRequest request) {
        InstitutionResponse response = institutionService.createInstitution(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<InstitutionResponse>> getAllInstitutions() {
        List<InstitutionResponse> responses = institutionService.getAllInstitutions();
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<InstitutionResponse> getInstitutionById(@PathVariable UUID id) {
        InstitutionResponse response = institutionService.getInstitutionById(id);
        return ResponseEntity.ok(response);
    }
}
