package com.gencel.backend.service;

import com.gencel.backend.dto.CreateInstitutionRequest;
import com.gencel.backend.dto.InstitutionResponse;
import com.gencel.backend.entity.Institution;
import com.gencel.backend.repository.InstitutionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("InstitutionService")
class InstitutionServiceTest {

    @Mock
    private InstitutionRepository institutionRepository;

    @InjectMocks
    private InstitutionService institutionService;

    private CreateInstitutionRequest validRequest;
    private Institution savedInstitution;

    @BeforeEach
    void setUp() {
        validRequest = CreateInstitutionRequest.builder()
                .name("Test Kurumu")
                .region("Ankara/Çankaya")
                .contactInfo("0312 123 45 67")
                .build();

        savedInstitution = Institution.builder()
                .id(UUID.randomUUID())
                .name(validRequest.getName())
                .region(validRequest.getRegion())
                .contactInfo(validRequest.getContactInfo())
                .isActive(true)
                .build();
    }

    @Nested
    @DisplayName("createInstitution")
    class CreateInstitution {

        @Test
        @DisplayName("geçerli istek ile kurum oluşturur")
        void shouldCreateInstitutionWithValidRequest() {
            when(institutionRepository.save(any(Institution.class))).thenReturn(savedInstitution);

            InstitutionResponse response = institutionService.createInstitution(validRequest);

            assertThat(response).isNotNull();
            assertThat(response.getId()).isEqualTo(savedInstitution.getId());
            assertThat(response.getName()).isEqualTo("Test Kurumu");
            assertThat(response.getRegion()).isEqualTo("Ankara/Çankaya");
            assertThat(response.getContactInfo()).isEqualTo("0312 123 45 67");
            assertThat(response.getIsActive()).isTrue();
            assertThat(response.getCreatedAt()).isNull(); // Mock'ta set edilmedi

            ArgumentCaptor<Institution> captor = ArgumentCaptor.forClass(Institution.class);
            verify(institutionRepository).save(captor.capture());
            Institution captured = captor.getValue();
            assertThat(captured.getName()).isEqualTo(validRequest.getName());
            assertThat(captured.getIsActive()).isTrue();
        }

        @Test
        @DisplayName("contactInfo null ise de çalışır")
        void shouldCreateWithOptionalContactInfo() {
            validRequest.setContactInfo(null);
            savedInstitution.setContactInfo(null);
            when(institutionRepository.save(any(Institution.class))).thenReturn(savedInstitution);

            InstitutionResponse response = institutionService.createInstitution(validRequest);

            assertThat(response.getContactInfo()).isNull();
        }
    }

    @Nested
    @DisplayName("getAllInstitutions")
    class GetAllInstitutions {

        @Test
        @DisplayName("tüm kurumları listeler")
        void shouldReturnAllInstitutions() {
            Institution inst2 = Institution.builder().id(UUID.randomUUID()).name("Kurum 2").region("İstanbul").build();
            when(institutionRepository.findAll()).thenReturn(List.of(savedInstitution, inst2));

            List<InstitutionResponse> result = institutionService.getAllInstitutions();

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getName()).isEqualTo("Test Kurumu");
            assertThat(result.get(1).getName()).isEqualTo("Kurum 2");
        }

        @Test
        @DisplayName("boş liste döner")
        void shouldReturnEmptyListWhenNoInstitutions() {
            when(institutionRepository.findAll()).thenReturn(List.of());

            List<InstitutionResponse> result = institutionService.getAllInstitutions();

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("getInstitutionById")
    class GetInstitutionById {

        @Test
        @DisplayName("geçerli ID ile kurum döner")
        void shouldReturnInstitutionWhenExists() {
            when(institutionRepository.findById(savedInstitution.getId())).thenReturn(Optional.of(savedInstitution));

            InstitutionResponse result = institutionService.getInstitutionById(savedInstitution.getId());

            assertThat(result).isNotNull();
            assertThat(result.getId()).isEqualTo(savedInstitution.getId());
            assertThat(result.getName()).isEqualTo(savedInstitution.getName());
        }

        @Test
        @DisplayName("mevcut olmayan ID için exception fırlatır")
        void shouldThrowWhenInstitutionNotFound() {
            UUID nonExistentId = UUID.randomUUID();
            when(institutionRepository.findById(nonExistentId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> institutionService.getInstitutionById(nonExistentId))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Institution not found");
        }
    }
}
