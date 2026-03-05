package com.gencel.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUserProfileRequest {

    @Size(max = 100, message = "First name must be at most 100 characters")
    private String firstName;

    @Size(max = 100, message = "Last name must be at most 100 characters")
    private String lastName;

    @Size(max = 20, message = "Phone number must be at most 20 characters")
    private String phoneNumber;

    @Email(message = "Email must be valid")
    private String email;

    @Size(max = 255, message = "Address must be at most 255 characters")
    private String address;

    @Size(max = 34, message = "IBAN must be at most 34 characters")
    private String iban;
}

