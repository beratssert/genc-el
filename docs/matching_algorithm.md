# Bildirim ve Eşleşme Algoritması (Redis + Queue + Realtime)

Bu doküman, "Yaşlı bir birey talep oluşturduğunda, sırayla en uygun öğrencinin nasıl bulunacağı" sürecini teknik olarak açıklar.

## Kullanılan Teknolojiler
- **PostgreSQL:** Yakındaki öğrencileri ve bekleyen görevleri filtrelemek için (Haversine tabanlı sorgular).
- **Redis List:** Aday öğrencileri sıraya dizmek için.
- **Redis Key-Value (TTL):** Cevap süresini (10dk) yönetmek için.
- **Spring Boot Event Listener:** Redis'ten gelen süre dolumu olaylarını dinlemek için.
- **FCM:** Kullanıcıya push bildirim göndermek için.
- **WebSocket/STOMP:** Task durumlarını anlık yayınlamak için.

## Algoritma Akışı

### 1. Talep Oluşturma (Trigger)
Ayşe Teyze "Öğrenci Çağır" butonuna bastığında:
1.  Sistem `users` tablosundan **1 km yarıçapındaki** (parametre değiştirilebilir), `is_active=true` olan ve şu an başka görevi olmayan öğrencileri sorgular.
    - Bu filtre artık veritabanı tarafında çalışır; Redis'e yalnızca aday kuyruğu yazılır.
2.  Bulunan öğrencileri öncelik sırasına göre dizer:
    - **1. Kriter:** O ay tamamladığı görev sayısı **AZ** olan en üstte (Adil dağılım için).
    - **2. Kriter:** Görev sayıları eşitse, konumu **YAKIN** olan en üstte.
3.  Bu listeyi Redis'e bir kuyruk (List) olarak atar.
    - **Key:** `task_candidates:{taskId}`
    - **Value:** `[StudentId_3 (0 görev), StudentId_1 (2 görev), StudentId_5 (5 görev)...]`

### 2. İlk Atama (Assignment)
1.  Redis listesinden ilk öğrenci (`StudentId_1`) çekilir (Pop).
2.  Sistemde geçici bir "Bekleniyor" kilidi oluşturulur.
    - **Key:** `pending_assignment:{taskId}`
    - **Value:** `StudentId_1`
    - **TTL (Süre):** 10 Dakika (600 saniye).
3.  Öğrenciye FCM üzerinden bildirim gider.
4.  Aynı anda realtime event yayınlanır (`TASK_ASSIGNED` / `TASK_REASSIGNED`) ve UI anlık güncellenir.

### 3. Senaryolar

#### Senaryo A: Öğrenci Kabul Eder (Happy Path)
1.  Ahmet (StudentId_1) "Kabul Et" butonuna basar.
2.  API'ye `PUT /api/v1/tasks/{taskId}/assign` isteği gelir.
3.  Backend:
    - Redis'teki `pending_assignment:{taskId}` anahtarını siler (Süreyi durdurur).
    - Redis'teki `task_candidates:{taskId}` listesini siler (Diğerlerine gerek kalmadı).
    - Veritabanında Task Status = `ASSIGNED` olur.
    - Bildirim Ayşe Teyze'ye gider: *"Ahmet yola çıktı!"*

#### Senaryo B: Öğrenci Reddeder
1.  Ahmet "Reddet" butonuna basar.
2.  API'ye `PUT /api/v1/tasks/{taskId}/reject` isteği gelir.
3.  Backend:
    - Redis'teki `pending_assignment:{taskId}` anahtarını siler.
    - **Döngü:** Kuyrukta (Redis List) bir sonraki öğrenci var mı?
        - **Evet (Berat):** Berat'ı çek, tekrar Adım 2'yi (İlk Atama) uygula.
        - **Hayır:** Kuyruk bitti. Ayşe Teyze'ye bildirim gönder: *"Maalesef şu an uygun öğrenci bulunamadı."* (Task Status = `CANCELLED` veya `TIMED_OUT`).

#### Senaryo C: Süre Dolar (Timeout)
1.  Ahmet 10 dakika boyunca hiçbir şeye basmaz.
2.  Redis'teki `pending_assignment:{taskId}` anahtarının süresi (TTL) dolar.
3.  Redis **"Key Expired Event"** fırlatır.
4.  Spring Boot tarafındaki `RedisMessageListener` bu olayı yakalar.
5.  Sistem otomatik olarak **Senaryo B (Reddetmiş gibi)** işlemini uygular:
    - Sıradaki öğrenciye geç.

## Veri Yapısı Özeti

| Redis Key | Tip | Amaç | TTL |
| :--- | :--- | :--- | :--- |
| `task_candidates:{taskId}` | List | Olası adayların listesi | 1 Saat (Task iptal olmazsa diye) |
| `pending_assignment:{taskId}` | String | Şu an cevap beklenen öğrenci | **10 Dakika** |

## Realtime Yayın Kanalı

- STOMP endpoint: `/ws`
- Institution topic: `/topic/institutions/{institutionId}/tasks`
- User topic: `/topic/users/{userId}/tasks`

Yayınlanan başlıca eventler:
- `TASK_CREATED`
- `TASK_ASSIGNED`
- `TASK_REASSIGNED`
- `TASK_STARTED`
- `TASK_DELIVERED`
- `TASK_COMPLETED`
- `TASK_CANCELLED`
- `TASK_RECEIPT_UPLOADED`

## Avantajları
- **Yüksek Performans:** Süre sayımı ve kuyruk yönetimi tamamen bellekte (RAM) döner.
- **Otomasyon:** Cron job yazıp dakikada bir veritabanını taramaya gerek kalmaz. Süre dolduğu an sistem tepki verir.
- **Ölçeklenebilirlik:** Binlerce talep aynı anda olsa bile DB yorulmaz.
