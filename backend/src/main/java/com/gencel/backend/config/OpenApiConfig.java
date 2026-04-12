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
                        
                        Rol yetkileri:
                        - **SYSTEM_ADMIN**: Sadece institution CRUD (POST/GET/PUT/DELETE /api/v1/institution). User yönetimi yapamaz.
                        - **INSTITUTION_ADMIN**: Kendi kurumunu günceller/siler (PUT/DELETE /api/v1/institution/me); kendi kurumuna bağlı STUDENT/ELDERLY oluşturur ve listeler.
                        - **STUDENT / ELDERLY**: Kendi profil işlemleri ve görev akışları.
                        
                        Kullanım:
                        1. Süper admin: `POST /api/v1/admin/login`
                        2. Kurum yöneticisi: `POST /api/v1/institution/login`
                        3. Öğrenci / yaşlı: `POST /api/v1/user/login`
                        4. Dönen JWT token'ı **Authorize** ile `Bearer <token>` olarak girin.
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
