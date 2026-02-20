# Postman Test Örnekleri

## Ön Hazırlık

### 1. Uygulamayı Başlatın
```bash
cd backend
mvn spring-boot:run
# veya Docker ile
docker-compose up
```

### 2. Test Admin Kullanıcısı Oluşturma

**ÖNEMLİ:** Test için önce bir admin kullanıcısının şifresini BCrypt ile hash'lemeniz gerekiyor. 

**Seçenek 1:** Veritabanında zaten admin kullanıcıları var (data.sql'de), ancak şifreleri hash'lenmemiş. Test için şu adımları izleyin:

1. Uygulamayı başlatın
2. Aşağıdaki login endpoint'ini kullanarak test edin (şifre: `admin123` - eğer data.sql'deki şifreleri güncellediyseniz)

**Seçenek 2:** Manuel olarak admin kullanıcısı oluşturmak için:
- PostgreSQL'e bağlanın
- Admin kullanıcısının şifresini BCrypt ile hash'leyin
- Veritabanını güncelleyin

---

## Test Senaryoları

### 1. Login (Kimlik Doğrulama)

**Endpoint:** `POST http://localhost:8080/api/v1/auth/login`

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "email": "admin@ankara.com",
  "password": "admin123"
}
```

**Beklenen Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "admin@ankara.com",
  "role": "INSTITUTION_ADMIN"
}
```

**Not:** `token` değerini kopyalayın, sonraki isteklerde kullanacaksınız.

---

### 2. Yeni Öğrenci Ekleme (INSTITUTION_ADMIN Yetkisi Gerekli)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <YUKARIDAKI_TOKEN_BURAYA>
```

**Body (JSON) - Öğrenci:**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "STUDENT",
  "firstName": "Ahmet",
  "lastName": "Yılmaz",
  "phoneNumber": "05551234567",
  "email": "ahmet.yilmaz@example.com",
  "password": "SecurePass123",
  "address": "Ankara, Çankaya, Kızılay Mahallesi",
  "latitude": 39.9334,
  "longitude": 32.8597,
  "iban": "TR330006100519786457841326"
}
```

**Beklenen Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "STUDENT",
  "firstName": "Ahmet",
  "lastName": "Yılmaz",
  "phoneNumber": "05551234567",
  "email": "ahmet.yilmaz@example.com",
  "address": "Ankara, Çankaya, Kızılay Mahallesi",
  "latitude": 39.9334,
  "longitude": 32.8597,
  "isActive": true,
  "iban": "TR330006100519786457841326",
  "createdAt": "2026-02-20T10:30:00"
}
```

---

### 3. Yeni Yaşlı Ekleme (INSTITUTION_ADMIN Yetkisi Gerekli)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <YUKARIDAKI_TOKEN_BURAYA>
```

**Body (JSON) - Yaşlı:**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "ELDERLY",
  "firstName": "Fatma",
  "lastName": "Demir",
  "phoneNumber": "05321234567",
  "email": "fatma.demir@example.com",
  "password": "SecurePass123",
  "address": "Ankara, Çankaya, Bahçelievler Mahallesi",
  "latitude": 39.9200,
  "longitude": 32.8600
}
```

**Beklenen Response (201 Created):**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "ELDERLY",
  "firstName": "Fatma",
  "lastName": "Demir",
  "phoneNumber": "05321234567",
  "email": "fatma.demir@example.com",
  "address": "Ankara, Çankaya, Bahçelievler Mahallesi",
  "latitude": 39.9200,
  "longitude": 32.8600,
  "isActive": true,
  "iban": null,
  "createdAt": "2026-02-20T10:35:00"
}
```

---

## Hata Senaryoları

### 1. Yetkisiz Erişim (Token Yok)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
```

**Body:** (Herhangi bir JSON)

**Beklenen Response (401 Unauthorized):**
```json
{
  "error": "Unauthorized"
}
```

---

### 2. Yanlış Rol (STUDENT veya ELDERLY ile Erişim)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <STUDENT_VEYA_ELDERLY_TOKEN>
```

**Beklenen Response (403 Forbidden):**
```json
{
  "error": "Access Denied"
}
```

---

### 3. Geçersiz Veri (Email Zaten Var)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <ADMIN_TOKEN>
```

**Body:**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "STUDENT",
  "firstName": "Test",
  "lastName": "User",
  "phoneNumber": "05551234567",
  "email": "ahmet.yilmaz@example.com",
  "password": "SecurePass123",
  "iban": "TR330006100519786457841326"
}
```

**Beklenen Response (400 Bad Request):**
```json
{
  "error": "User with email ahmet.yilmaz@example.com already exists"
}
```

---

### 4. Öğrenci için IBAN Eksik

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <ADMIN_TOKEN>
```

**Body:**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "STUDENT",
  "firstName": "Test",
  "lastName": "User",
  "phoneNumber": "05551234567",
  "email": "test@example.com",
  "password": "SecurePass123"
}
```

**Beklenen Response (400 Bad Request):**
```json
{
  "error": "IBAN is required for STUDENT role"
}
```

---

### 5. Geçersiz Rol (INSTITUTION_ADMIN Eklemeye Çalışma)

**Endpoint:** `POST http://localhost:8080/api/v1/users`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <ADMIN_TOKEN>
```

**Body:**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "INSTITUTION_ADMIN",
  "firstName": "Test",
  "lastName": "Admin",
  "phoneNumber": "05551234567",
  "email": "testadmin@example.com",
  "password": "SecurePass123"
}
```

**Beklenen Response (400 Bad Request):**
```json
{
  "error": "Only STUDENT or ELDERLY roles can be created through this endpoint"
}
```

---

## Postman Collection İçin Öneriler

1. **Environment Variables Oluşturun:**
   - `base_url`: `http://localhost:8080`
   - `token`: Login sonrası otomatik set edilecek

2. **Pre-request Script (Login için):**
   - Login isteğinden sonra token'ı environment variable'a kaydedin

3. **Test Script (User Create için):**
   - Response status code'un 201 olduğunu kontrol edin
   - Response body'de `id` field'ının olduğunu kontrol edin

---

## Hızlı Test Adımları

1. ✅ Uygulamayı başlatın
2. ✅ Login endpoint'ini çağırın ve token alın
3. ✅ Token'ı Authorization header'a ekleyin
4. ✅ POST /api/v1/users endpoint'ini çağırın
5. ✅ Response'u kontrol edin

**Not:** Eğer data.sql'deki admin şifreleri hash'lenmemişse, önce veritabanını güncelleyin veya yeni bir admin kullanıcısı oluşturun.
