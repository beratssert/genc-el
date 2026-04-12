# Backend Ekibi İçin Yapılacaklar

## 🔴 Kritik — Register Endpoint


### Seçenek 1: Seed Data (Önerilen — Hızlı Çözüm)
`data.sql` ile başlangıç verisi oluştur:

```sql
-- Kurum oluştur
INSERT INTO institutions (id, name, region, contact_info, is_active, created_at) 
VALUES ('11111111-1111-1111-1111-111111111111', 'Antalya Büyükşehir Belediyesi', 'Antalya', 'info@antalya.bel.tr', true, NOW());

-- Kurum admini oluştur (şifre: Admin123)
-- BCrypt hash: $2a$10$... (passwordEncoder.encode("Admin123") ile üretilmeli)
INSERT INTO users (id, institution_id, role, first_name, last_name, phone_number, email, password_hash, address, is_active, created_at) 
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'INSTITUTION_ADMIN',
  'Admin', 'Kullanıcı',
  '0500 000 00 00',
  'admin@gencel.com',
  '$2a$10$HASH_BURAYA', -- BCrypt ile encode edilmeli
  'Antalya Merkez',
  true, NOW()
);

-- Test yaşlı kullanıcı (şifre: Test1234)
INSERT INTO users (id, institution_id, role, first_name, last_name, phone_number, email, password_hash, address, latitude, longitude, is_active, created_at)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  'ELDERLY',
  'Mehmet', 'Demir',
  '0532 123 45 67',
  'mehmet@test.com',
  '$2a$10$HASH_BURAYA',
  'Konyaaltı, Antalya',
  36.8841, 30.6892,
  true, NOW()
);

-- Test öğrenci kullanıcı (şifre: Test1234)
INSERT INTO users (id, institution_id, role, first_name, last_name, phone_number, email, password_hash, address, latitude, longitude, is_active, iban, created_at)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  '11111111-1111-1111-1111-111111111111',
  'STUDENT',
  'Ahmet', 'Yılmaz',
  '0543 234 56 78',
  'ahmet@test.com',
  '$2a$10$HASH_BURAYA',
  'Akdeniz Üniversitesi, Antalya',
  36.8955, 30.6394,
  true,
  'TR000000000000000000000001',
  NOW()
);
```


## 🟡 İyileştirmeler

### 1. Password Change Endpoint
`POST /api/v1/auth/change-password` — api_endpoints.md'de tanımlanmış ama controller'da yok.

### 2. Logout / Token Invalidation
Şu anda JWT token'ı invalidate etme mekanizması yok. Redis'e eklenen bir blacklist ile çözülebilir.

### 3. User Search/Filter
`GET /api/v1/user` endpoint'inde isim veya telefon ile arama desteği eklenebilir:
```
GET /api/v1/user?role=STUDENT&search=Ahmet
```

### 4. Task — requester bilgisi
`TaskResponse`'da sadece `requesterId` (UUID) var. Frontend'de yaşlının adını göstermek için ya:
- `TaskResponse`'a `requesterFirstName`, `requesterLastName` eklenmeli
- Ya da frontend ayrıca `GET /api/v1/user/{id}` çağıracak (ama bu yetki gerektiriyor)

**Öneri:** `TaskResponse`'a şu alanları ekle:
```java
private String requesterFirstName;
private String requesterLastName;
private String requesterAddress;
private String volunteerFirstName;
private String volunteerLastName;
```

### 5. Nearby Tasks Endpoint
`GET /api/v1/tasks/nearby?lat=X&lon=Y&radius=Z` — api_endpoints.md'de tanımlanmış ama controller'da sadece `GET /api/v1/tasks/pending` var. Konum-bazlı filtreleme eklenebilir.

---

## 🟢 Frontend Uyumluluk Notları

Frontend aşağıdaki şekilde backend'e bağlanıyor:
- **JSON Format:** camelCase (Spring Boot default — uyumlu ✅)
- **Auth:** Bearer token header'da gönderiliyor ✅
- **Base URL:** `http://localhost:8080` (Docker port mapping ile uyumlu ✅)
