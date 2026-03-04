# API Uç Noktaları (Endpoints)

Tüm endpointler `/api/v1` ön ekiyle başlar.

## 1. Kurum Yönetimi (Institution Management)

Kurum kayıtları ve kurum yöneticisi (INSTITUTION_ADMIN) girişi.

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/v1/institution/login` | Kurum yöneticisi girişi. E-posta ve şifre ile JWT token döner. |
| `POST` | `/api/v1/institution` | Yeni kurum oluştur. |
| `GET` | `/api/v1/institution` | Tüm kurumları listele. |
| `GET` | `/api/v1/institution/{id}` | ID ile kurum detayı getir. |

### Kurum Oluşturma (POST /api/v1/institution)
```json
{
  "name": "Ankara Belediyesi Sosyal Hizmetler",
  "region": "Ankara/Çankaya",
  "contactInfo": "0312 123 45 67"
}
```

### Kurum Giriş (POST /api/v1/institution/login)
```json
{
  "email": "admin@kurum.gov.tr",
  "password": "GucluSifre123"
}
```

### Kurum Yanıtı (InstitutionResponse)
```json
{
  "id": "uuid",
  "name": "string",
  "region": "string",
  "contactInfo": "string",
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00"
}
```

## 2. Kullanıcı Yönetimi (User Management)

Kurum yöneticisi (INSTITUTION_ADMIN) kendi kurumuna bağlı öğrenci ve yaşlı kullanıcıları yönetir.

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `POST` | `/api/v1/user/login` | Öğrenci/Yaşlı girişi. JWT token döner. | Public |
| `POST` | `/api/v1/user` | Kurum kullanıcısı (STUDENT/ELDERLY) oluştur. | INSTITUTION_ADMIN |
| `GET` | `/api/v1/user` | Kurum kullanıcılarını listele. | INSTITUTION_ADMIN |

### Query Parametreleri (GET /api/v1/user)
- `role` (opsiyonel): `STUDENT` veya `ELDERLY` ile filtreleme.

### Kullanıcı Oluşturma (POST /api/v1/user)
```json
{
  "role": "STUDENT",
  "firstName": "Ahmet",
  "lastName": "Yılmaz",
  "phoneNumber": "0532 123 45 67",
  "email": "ahmet@example.com",
  "password": "GucluSifre123",
  "address": "Ankara, Çankaya",
  "latitude": 39.9334,
  "longitude": 32.8597,
  "iban": "TR00 0000 0000 0000 0000 0000 00"
}
```

`iban` sadece `STUDENT` rolü için kullanılır. Şifre en az 8 karakter, en az bir büyük harf, bir küçük harf ve bir rakam içermelidir.

---

## 3. Planlanan Endpointler (Henüz Implement Edilmemiş)

### Kimlik Doğrulama (Auth)
- `POST /api/v1/auth/refresh-token`: Token yenileme.
- `POST /api/v1/auth/change-password`: Şifre değiştirme.

### Kullanıcı CRUD (Genişletilecek)
- `GET /api/v1/user/{id}`: Kullanıcı detayı.
- `PUT /api/v1/user/{id}`: Kullanıcı güncelle.
- `DELETE /api/v1/user/{id}`: Kullanıcıyı pasife al (Soft delete).
- `GET /api/v1/user/{id}/history`: Kullanıcının geçmiş görevleri.

### Görev Yönetimi (Task Operations)
- `POST /api/v1/tasks`: Yeni alışveriş isteği oluştur.
- `GET /api/v1/tasks/nearby`: Konuma göre yakındaki PENDING görevleri listele.
- `GET /api/v1/tasks/my-active-task`: Öğrencinin üzerindeki aktif görevi getir.
- `PUT /api/v1/tasks/{id}/accept`: Görevi kabul et.
- `PUT /api/v1/tasks/{id}/start-shopping`: Alışverişe başladı.
- `PUT /api/v1/tasks/{id}/complete-shopping`: Alışveriş bitti.
- `POST /api/v1/tasks/{id}/receipt`: Fiş fotoğrafı yükle.
- `PUT /api/v1/tasks/{id}/complete`: Görev tamamlandı.
- `PUT /api/v1/tasks/{id}/confirm-start`: Yaşlı başlangıç onayı.
- `PUT /api/v1/tasks/{id}/confirm-end`: Yaşlı teslimat onayı.

### Kurum İstatistikleri & Burs
- `GET /api/v1/institution/my-stats`: Kurumun genel istatistikleri.
- `GET /api/v1/bursaries`: Öğrenci hakediş listesi.
- `POST /api/v1/bursaries/calculate`: Burs hesaplaması tetikle.
- `PUT /api/v1/bursaries/{id}/pay`: Ödeme yapıldı işaretle.
