# API Uç Noktaları (Endpoints)

Tüm endpointler `/api/v1` ön ekiyle başlar.

## 1. Kimlik Doğrulama (Auth)

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `POST` | `/api/v1/user/login` | Öğrenci/yaşlı girişi. JWT döner. | Public |
| `POST` | `/api/v1/institution/login` | Kurum yöneticisi girişi. JWT döner. | Public |
| `POST` | `/api/v1/admin/login` | Sistem yöneticisi girişi. JWT döner. | Public |
| `POST` | `/api/v1/auth/refresh-token` | Giriş yapmış kullanıcı için yeni JWT üretir. | Authenticated |
| `POST` | `/api/v1/auth/change-password` | Mevcut şifre doğrulanarak yeni şifreye geçilir. | Authenticated |

## 2. Kurum Yönetimi (Institution Management)

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `POST` | `/api/v1/institution` | Yeni kurum oluşturur. | SYSTEM_ADMIN |
| `GET` | `/api/v1/institution` | Tüm kurumları listeler. | SYSTEM_ADMIN |
| `GET` | `/api/v1/institution/{id}` | Kurum detayı getirir. | SYSTEM_ADMIN |
| `PUT` | `/api/v1/institution/{id}` | Kurum bilgisini günceller. | SYSTEM_ADMIN |
| `DELETE` | `/api/v1/institution/{id}` | Kurumu pasife alır. | SYSTEM_ADMIN |
| `PUT` | `/api/v1/institution/me` | Kendi kurumunu günceller. | INSTITUTION_ADMIN |
| `DELETE` | `/api/v1/institution/me` | Kendi kurumunu pasife alır. | INSTITUTION_ADMIN |

## 3. Kullanıcı Yönetimi (User Management)

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `POST` | `/api/v1/user` | Kuruma bağlı STUDENT/ELDERLY oluşturur. | INSTITUTION_ADMIN |
| `GET` | `/api/v1/user` | Kurumdaki kullanıcıları listeler. | INSTITUTION_ADMIN |
| `GET` | `/api/v1/user/me` | Giriş yapan kullanıcının profilini döner. | Authenticated |
| `PUT` | `/api/v1/user/me` | Giriş yapan kullanıcının profilini günceller. | Authenticated |
| `PUT` | `/api/v1/user/me/device-token` | FCM cihaz tokenını kaydeder/günceller. | Authenticated |
| `DELETE` | `/api/v1/user/me` | Hesabı soft-delete yapar. | Authenticated |
| `GET` | `/api/v1/user/nearby-students` | Yaşlı kullanıcı için yakın müsait öğrencileri listeler. | ELDERLY |

### Query Parametreleri
- `GET /api/v1/user`: `role` (opsiyonel, `STUDENT`/`ELDERLY`)
- `GET /api/v1/user/nearby-students`: `latitude`, `longitude`, `radiusKm` (hepsi opsiyonel)

## 4. Görev Yönetimi (Task Operations)

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `POST` | `/api/v1/tasks` | Yeni alışveriş görevi oluşturur. | ELDERLY |
| `GET` | `/api/v1/tasks/pending` | Bekleyen görevleri listeler. | Authenticated |
| `GET` | `/api/v1/tasks/nearby` | Öğrenci için yakındaki PENDING görevleri listeler. | STUDENT |
| `GET` | `/api/v1/tasks/my-tasks` | Kullanıcının kendi görevlerini listeler. | Authenticated |
| `GET` | `/api/v1/tasks/my-active-task` | Öğrencinin aktif görevini döner (`ASSIGNED`/`IN_PROGRESS`). | STUDENT |
| `PUT` | `/api/v1/tasks/{taskId}/assign` | Öğrenci görevi kabul eder. | STUDENT |
| `PUT` | `/api/v1/tasks/{taskId}/reject` | Öğrenci görevi reddeder. | STUDENT |
| `PUT` | `/api/v1/tasks/{taskId}/confirm-start` | Yaşlı kullanıcı başlangıcı onaylar. | ELDERLY |
| `PUT` | `/api/v1/tasks/{taskId}/start` | Öğrenci alışverişe başlar. | STUDENT |
| `PUT` | `/api/v1/tasks/{taskId}/deliver` | Öğrenci teslimatı bildirir. | STUDENT |
| `PUT` | `/api/v1/tasks/{taskId}/confirm-end` | Yaşlı kullanıcı teslimatı onaylar. | ELDERLY |
| `PUT` | `/api/v1/tasks/{taskId}/complete` | Yaşlı kullanıcı görevi tamamlar. | ELDERLY |
| `PUT` | `/api/v1/tasks/{taskId}/cancel` | Görev iptal eder. | Requester or Volunteer |
| `POST` | `/api/v1/tasks/{taskId}/receipt/upload` | Makbuz görseli yükler. | ELDERLY |

## 5. Dashboard ve Burs

| Method | Endpoint | Açıklama | Yetki |
|--------|----------|----------|-------|
| `GET` | `/api/v1/dashboard/stats` | Dashboard istatistiklerini döner. | Authenticated |
| `GET` | `/api/v1/bursaries/me` | Öğrencinin burs hareketlerini getirir. | STUDENT |
| `GET` | `/api/v1/bursaries/institution` | Kuruma ait burs hareketlerini listeler. | INSTITUTION_ADMIN |
| `POST` | `/api/v1/bursaries/calculate` | Burs hesaplamasını tetikler. | INSTITUTION_ADMIN |
| `PUT` | `/api/v1/bursaries/{id}/pay` | Burs kaydını ödendi işaretler. | INSTITUTION_ADMIN |

## 6. Realtime (WebSocket)

### Bağlantı
- STOMP endpoint: `/ws`

### Topicler
- `/topic/institutions/{institutionId}/tasks`
- `/topic/users/{userId}/tasks`

### Event Türleri
- `TASK_CREATED`
- `TASK_ASSIGNED`
- `TASK_REASSIGNED`
- `TASK_REJECTED`
- `TASK_START_CONFIRMED`
- `TASK_STARTED`
- `TASK_DELIVERED`
- `TASK_DELIVERY_CONFIRMED`
- `TASK_COMPLETED`
- `TASK_CANCELLED`
- `TASK_RECEIPT_UPLOADED`

## 7. Hala Planlananlar

- `GET /api/v1/user/{id}`
- `PUT /api/v1/user/{id}`
- `DELETE /api/v1/user/{id}`
- `GET /api/v1/user/{id}/history`
