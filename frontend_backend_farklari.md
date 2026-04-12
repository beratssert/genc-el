# Genç-El Uygulaması: Backend - Frontend Özellik Karşılaştırması

Bu belge, Spring Boot (Backend) projesindeki mevcut API uç noktaları ve özellikleri ile Flutter (Frontend) tarafındaki implementasyonların detaylı analizini içermektedir. Genel tabloya bakıldığında **Backend tarafının Frontend'den çok daha ileride olduğu** ve Frontend tarafında uygulanmayı bekleyen birçok özellik (özellikle canlık konum, realtime bildirimler, gelişmiş görev onay mekanizmaları) olduğu görülmektedir.

## 1. Authentication & Security (Kimlik Doğrulama)

| Özellik | Backend Durumu | Frontend Durumu (Dart/UI) | Durum |
| :--- | :--- | :--- | :--- |
| Öğrenci/Yaşlı Girişi (`/user/login`) | ✅ Aktif | ✅ `userLogin` var | Tamamlandı |
| Kurum Yöneticisi Girişi (`/inst/login`) | ✅ Aktif | ✅ `institutionLogin` var | Tamamlandı |
| Sistem Yöneticisi Girişi (`/admin/login`)| ✅ Aktif | ❌ Yok | **Eksik** |
| Token Yenileme (`/refresh-token`) | ✅ Aktif | ❌ Yok | **Eksik** (Oturum süresi dolunca uygulamadan atar) |
| Şifre Değiştirme (`/change-password`) | ✅ Aktif | ❌ Yok | **Eksik** |

## 2. Kurum Yönetimi (Institution Management)

| Özellik | Backend Durumu | Frontend Durumu | Durum |
| :--- | :--- | :--- | :--- |
| Kurum Detayları (`/institution/me`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| System Admin Kurum CRUD İşlemleri | ✅ Aktif | ❌ Yok | **Eksik** (Sistem Yöneticisi arayüzü yok) |

## 3. Kullanıcı Yönetimi ve Profil (User Management)

Yakın zamanda yapılan güncellemeler sayesinde Kurum Yöneticisi'nin kendi kullanıcılarını sayfalayarak listelemesi, CRUD yapması ve geçmişlerini görmesi eklenmiştir.

| Özellik | Backend Durumu | Frontend Durumu | Durum |
| :--- | :--- | :--- | :--- |
| Kullanıcı Filtreleme, Listeleme, Sayfalama | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Kullanıcı Geçmişi ve Detaylı CRUD | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Profil Görüntüleme/Güncelleme (`/me`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| **Canlı Konum Güncelleme** (`/me/location`) | ✅ Aktif | ❌ Yok | **Eksik** (GPS entegrasyonu Backend'e bağlı değil) |
| **Cihaz Token Kaydı** (`/me/device-token`) | ✅ Aktif | ❌ Yok | **Eksik** (FCM Push Notification bağlı değil) |
| Yakın Öğrencileri Listeleme (`/nearby-students`)| ✅ Aktif | ❌ Yok | **Eksik** (Yaşlılar için harita/yakın öğrenci listesi yok)|

## 4. Görev (Task) ve Alışveriş Operasyonları

Projenin merkezini oluşturan Task sistemi backend tarafında çok detaylı (onaylı) çalışırken, frontend tarafı görev akışının bazı detaylarını atlamaktadır.

| Özellik | Backend Durumu | Frontend Durumu | Durum |
| :--- | :--- | :--- | :--- |
| Görev Oluşturma (Yaşlı Tarafı) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Tüm Bekleyen Görevler (`/pending`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| **Yakındaki Görevler** (`/nearby`) | ✅ Aktif | ❌ Yok | **Eksik** (Öğrencilerin yakındaki siparişleri görmesi) |
| **Aktif Görevi Getir** (`/my-active-task`) | ✅ Aktif | ❌ Yok | **Eksik** (Öğrenci aktif görevini kaybedebiliyor) |
| Görevi Üzerine Al (`/assign`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Görevi Reddet (`/reject`) | ✅ Aktif | ❌ Yok | **Eksik** |
| Göreve Başla (`/start` vs `confirm-start`) | ✅ İki aşamalı | ⚠️ Sadece Öğrenci Başlatıyor | **Eksik/Uyumsuz** (Yaşlının `confirm-start` onayı yok) |
| Görevi Teslim Et (`/deliver`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Görevi Tamamla (`/complete` vs `confirm-end`) | ✅ İki aşamalı | ⚠️ Doğrudan tamamlanıyor | **Eksik/Uyumsuz** (Yaşlının `confirm-end` onayı yok) |
| Makbuz/Fiş Yükleme (`/receipt/upload`) | ✅ Aktif (Upload) | ❌ Yok | **Eksik** (Kamera/Galeri entegrasyonu yok) |

## 5. Dashboard ve Burs Sistemi

Burs entegrasyon API'leri büyük oranda mevcut.
| Özellik | Backend Durumu | Frontend Durumu | Durum |
| :--- | :--- | :--- | :--- |
| İstatistikler (`/dashboard/stats`) | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Burs Hareketleri ve Listeler | ✅ Aktif | ✅ Mevcut | Tamamlandı |
| Burs Hesaplatma ve Ödeme İşaretleme | ✅ Aktif | ✅ Mevcut | Tamamlandı |

## 6. Realtime & Socket İletişimi (WebSocket)

Backend tarafında görev güncellemeleri anlık olarak yansısın ve konumlar anlık gözüksün diye entegre edilen geniş bir STOMP/WebSocket altyapısı bulunuyor. Frontend bu durumdan tamamen habersiz.

| Özellik | Backend Durumu | Frontend Durumu | Durum |
| :--- | :--- | :--- | :--- |
| STOMP `/ws` Bağlantısı | ✅ Aktif | ❌ `pubspec.yaml`'da paket dahi yok | **Kritik Eksik** |
| Görev Güncellemeleri (`TASK_CREATED` vs) | ✅ Aktif Push Mechanism | ❌ HTTP Polling veya Refresh| **Kritik Eksik** |
| Canlı Konum Akışı (`LocationRealtime`) | ✅ Aktif | ❌ Yok | **Kritik Eksik** |

---

## 🚀 Sonuç ve Özet
Frontend tarafında **fazla** olan hiçbir özellik yoktur; Frontend tamamen Backend'in arkasından gelmektedir. En acil eklenmesi/entegre edilmesi gereken eksikler şunlardır:

1. **WebSocket Entegrasyonu**: Uygulamanın "Uber gibi" çalışabilmesi, görev atandığında anlık bildirim düşmesi veya sayfa yenilenmesine gerek kalmadan işleyebilmesi için gerekli.
2. **Görev Onay (Confirm) Akışı**: Yaşlının parasını teslim etmesi ve siparişini eksiksiz aldığını teyit etmesi. Frontend şuan işlemi direkt olarak kapatıyor ama backend `confirm-start` ve `confirm-end` adımlarını yaşlıdan (kullanıcıdan) bekliyor olabilir.
3. **Konum (GPS) ve Fiş Yükleme**: `nearby-students`, `tasks/nearby` çalışabilmesi için cihazın konum servisleri açılıp `PUT /api/v1/user/me/location` ile düzenli konum güncellenmeli. Ayrıca makbuz yüklemek için kamera yetkisi alınmalı.
