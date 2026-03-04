package com.gencel.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "Genc-El API Documentation",
                description = """
                        Genc-El Projesi için REST API dökümantasyonu.

                        Kullanım önerisi:
                        1. Kurum yöneticisi girişi için: `POST /api/v1/institution/login`
                        2. Öğrenci / yaşlı kullanıcı girişi için: `POST /api/v1/user/login`
                        3. Dönen JWT token'ı sağ üstteki **Authorize** butonuna tıklayarak `Bearer <token>` formatında girin.
                        4. Ardından kurum ve kullanıcı yönetimi ile ilgili güvenli endpoint'leri (User Management, Institution Management) Swagger UI üzerinden rahatça test edebilirsiniz.
                        """,
                version = "1.0",
                contact = @Contact(
                        name = "Genc-El Backend Team"
                )
        ),
        security = {
                @SecurityRequirement(name = "bearerAuth")
        }
)
@SecurityScheme(
        name = "bearerAuth",
        description = "Giriş yaptıktan sonra aldığınız JWT token'ı buraya yapıştırın.",
        scheme = "bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        in = SecuritySchemeIn.HEADER
)
public class OpenApiConfig {
}
