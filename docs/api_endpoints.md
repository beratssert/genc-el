# API Uç Noktaları (Endpoints)

Tüm endpointler `/api/v1` ön ekiyle başlar.

## 1. Kimlik Doğrulama (Auth)
- `POST /api/v1/auth/login`: Kullanıcı girişi (JWT döner).
- `POST /api/v1/auth/refresh-token`: Token yenileme.
- `POST /api/v1/auth/change-password`: Şifre değiştirme.

## 2. Kullanıcı Yönetimi (User Management)
*Genellikle Kurum Yöneticisi tarafından kullanılır.*
- `POST /api/v1/users`: Yeni kullanıcı (Öğrenci/Yaşlı) ekle.
- `GET /api/v1/users`: Kullanıcıları listele (Filtre: Role, Region vb.).
- `GET /api/v1/users/{id}`: Kullanıcı detayı.
- `PUT /api/v1/users/{id}`: Kullanıcı güncelle.
- `DELETE /api/v1/users/{id}`: Kullanıcıyı pasife al (Soft delete).
- `GET /api/v1/users/{id}/history`: Kullanıcının geçmiş görevleri.

## 3. Görev Yönetimi (Task Operations)
Projenin kalbi olan alışveriş akışı buradadır.

### Talep Oluşturma (Yaşlı/Engelli)
- `POST /api/v1/tasks`: Yeni alışveriş isteği oluştur.
    - **Body:** `{ "shopping_list": [...], "notes": "..." }`

### Eşleşme ve Listeleme (Öğrenci)
- `GET /api/v1/tasks/nearby`: Konuma göre yakındaki `PENDING` görevleri listele.
    - **Query Params:** `lat`, `lon`, `radius` (km).
- `GET /api/v1/tasks/my-active-task`: Öğrencinin üzerindeki aktif görevi getir.

### Görev Akışı (Durum Güncellemeleri)
- `PUT /api/v1/tasks/{id}/accept`: Görevi kabul et (`ASSIGNED`).
- `PUT /api/v1/tasks/{id}/start-shopping`: Eve vardı, parayı aldı, alışverişe başladı (`SHOPPING`).
    - **Body:** `{ "received_amount": 100.0 }` (Teyit edilen para).
- `PUT /api/v1/tasks/{id}/complete-shopping`: Alışveriş bitti, eve dönüyor (`AT_HOME_FINAL`).
- `POST /api/v1/tasks/{id}/receipt`: Fiş fotoğrafı yükle.
    - **Multipart File:** Fiş görseli.
- `PUT /api/v1/tasks/{id}/complete`: Teslimat yapıldı, görev tamamlandı (`COMPLETED`).
    - **Body:** `{ "change_amount": 10.0 }` (Para üstü).

### Onay Mekanizması (Yaşlı/Engelli)
- `PUT /api/v1/tasks/{id}/confirm-start`: Yaşlı, verdiği parayı ve öğrencinin geldiğini onaylar.
- `PUT /api/v1/tasks/{id}/confirm-end`: Yaşlı, teslimatı ve para üstünü onaylar. Görev tamamen kapanır.

## 4. Kurum ve Burs Yönetimi (Institution & Bursary)
- `GET /api/v1/institutions/my-stats`: Kurumun genel istatistikleri.
- `GET /api/v1/bursaries`: Öğrenci hakediş listesi (Aylık/Yıllık filtreli).
- `POST /api/v1/bursaries/calculate`: Belirli bir ay için burs hesaplamasını tetikle (Cron da yapabilir ama manuel de olsun).
- `PUT /api/v1/bursaries/{id}/pay`: Ödeme yapıldı olarak işaretle.

## Örnek JSON Modelleri

### Görev Oluşturma (POST /api/v1/tasks)
```json
{
  "shopping_list": [
    { "item": "Ekmek", "qty": 2, "unit": "Adet" },
    { "item": "Süt", "qty": 1, "unit": "Lt" }
  ],
  "note": "Zili çalmayın, kapıyı tıklatın."
}
```

### Görev Tamamlama (PUT /api/v1/tasks/{id}/complete)
```json
{
  "change_amount": 15.50,
  "note": "Poşet parası dahil edildi."
}
```
