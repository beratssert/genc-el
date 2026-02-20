# Manuel Test Adımları

**Not:** Seed verisi artık `users` tablosuna yazılıyor (entity ile uyumlu). Uygulama her açılışta `data.sql` ile veritabanını sıfırlayıp tekrar doldurur (geliştirme ortamı için).

## 1. Backend’i Çalıştırma

### Seçenek A: Docker ile (önerilen)
```bash
cd /Users/halit/Desktop/genc-el
docker compose up -d
```
Tüm servisler (PostgreSQL, Redis, Backend) ayağa kalkar. Backend birkaç dakika içinde hazır olur.

### Seçenek B: Sadece DB + Redis Docker, backend yerelde
```bash
cd /Users/halit/Desktop/genc-el
docker compose up -d postgres redis
```
Sonra başka bir terminalde:
```bash
cd backend
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gencel_db
export SPRING_DATASOURCE_USERNAME=gencel_user
export SPRING_DATASOURCE_PASSWORD=gencel_password
export REDIS_HOST=localhost
export REDIS_PORT=6379
mvn spring-boot:run
```

---

## 2. Backend’in Hazır Olduğunu Kontrol Et

Tarayıcı veya curl:
```bash
curl -s http://localhost:8080/actuator/health 2>/dev/null || curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{}'
```
(Login’e boş body ile POST atınca 400 dönerse servis ayaktadır.)

---

## 3. Postman ile Test

### Adım 1: Login (token al)
- **Method:** POST  
- **URL:** `http://localhost:8080/api/v1/auth/login`  
- **Headers:** `Content-Type: application/json`  
- **Body (raw JSON):**
```json
{
  "email": "admin@ankara.com",
  "password": "admin123"
}
```
- **Beklenen:** 200 OK, body’de `token`, `email`, `role` alanları.  
- **Yapılacak:** `token` değerini kopyala.

---

### Adım 2: Kullanıcıları listele (GET /api/v1/users)
- **Method:** GET  
- **URL:** `http://localhost:8080/api/v1/users`  
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <yukarıda_kopyaladığın_token>`
- **Beklenen:** 200 OK, body’de kuruma bağlı kullanıcı listesi (JSON array).

**Role ile filtre:**
- Sadece öğrenciler: `http://localhost:8080/api/v1/users?role=STUDENT`
- Sadece yaşlılar: `http://localhost:8080/api/v1/users?role=ELDERLY`

---

### Adım 3: Yeni kullanıcı ekle (isteğe bağlı)
- **Method:** POST  
- **URL:** `http://localhost:8080/api/v1/users`  
- **Headers:**  
  - `Content-Type: application/json`  
  - `Authorization: Bearer <token>`  
- **Body (örnek – öğrenci):**
```json
{
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "role": "STUDENT",
  "firstName": "Test",
  "lastName": "Öğrenci",
  "phoneNumber": "05551234567",
  "email": "test.ogrenci@example.com",
  "password": "SecurePass123",
  "address": "Ankara",
  "iban": "TR330006100519786457841326"
}
```
- **Beklenen:** 201 Created, body’de oluşan kullanıcı bilgisi.

---

## 4. Terminalden curl ile Hızlı Test

Backend ayaktayken (token’ı kendin doldur):

```bash
# 1) Login ve token'ı kaydet
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ankara.com","password":"admin123"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 2) Kullanıcıları listele
curl -s -X GET "http://localhost:8080/api/v1/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq .

# 3) Sadece öğrenciler
curl -s -X GET "http://localhost:8080/api/v1/users?role=STUDENT" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq .
```

(jq yoksa komutun sonundaki `| jq .` kısmını kaldırıp çıktıyı ham JSON olarak görebilirsin.)

---

## Sorun Çıkarsa

| Belirti | Olası neden | Ne yapılır? |
|--------|----------------|-------------|
| Login 401 / "Bad credentials" | Şifre yanlış veya kullanıcı yok | data.sql’deki admin şifreleri BCrypt ile güncellendi mi kontrol et; email: `admin@ankara.com`, şifre: `admin123` |
| GET /users 403 | Token yok veya rol INSTITUTION_ADMIN değil | Login’i admin@ankara.com ile yap, dönen token’ı Authorization header’da kullan |
| GET /users boş liste [] | Kurumda kullanıcı yok | Önce POST /api/v1/users ile bir öğrenci/yaşlı ekle, sonra GET /users’ı tekrar dene |
| Connection refused | Backend kapalı | `docker compose up -d` veya `mvn spring-boot:run` ile backend’i başlat |

Bu adımlarla manuel testi tamamlayabilirsin.
