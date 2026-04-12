# Proje Planı: Sosyal Sorumluluk Uygulaması (Öğrenci - Yaşlı/Engelli Destek Ağı)

- [x] **Gereksinim Analizi ve Dokümantasyon** <!-- id: 0 -->
    - [x] Proje tanımının ve akışının netleştirilmesi <!-- id: 1 -->
    - [x] Kullanıcı rolleri ve yetkilerin belirlenmesi (Öğrenci, Yaşlı/Engelli, Kurum) <!-- id: 2 -->
    - [x] Teknik isterlerin belirlenmesi (Tech Stack) <!-- id: 3 -->
- [x] **Sistem Mimarisi Tasarımı** <!-- id: 4 -->
    - [x] Veritabanı şemasının tasarlanması (ER Diyagramı) <!-- id: 5 -->
    - [x] API uç noktalarının (Endpoints) belirlenmesi <!-- id: 6 -->
    - [x] Bildirim ve eşleşme algoritması mantığının kurgulanması <!-- id: 7 -->
- [x] **Backend Çekirdek Geliştirme** <!-- id: 8 -->
    - [x] Kurum/Kullanıcı/Görev/Burs API'leri <!-- id: 9 -->
    - [x] Redis tabanlı eşleşme kuyruğu <!-- id: 10 -->
    - [x] FCM bildirim altyapısı <!-- id: 11 -->
    - [x] Task confirmation flow (`confirm-start`, `confirm-end`) <!-- id: 12 -->
    - [x] Makbuz yükleme (local storage) <!-- id: 13 -->
    - [x] Realtime task event yayınları (WebSocket/STOMP) <!-- id: 14 -->
    - [x] Auth genişletmeleri (`refresh-token`, `change-password`) <!-- id: 15 -->
    - [x] Yakın görev/öğrenci ve aktif görev endpointleri <!-- id: 16 -->

- [ ] **Kalan Geliştirmeler (Opsiyonel/Ürün Kararı)** <!-- id: 17 -->
    - [x] User detail/history CRUD genişletmeleri <!-- id: 18 -->
    - [ ] Üretim ortamı WebSocket allowed origins sabitleme <!-- id: 19 -->
    - [ ] S3 gibi uzak depolama entegrasyonu (local storage yerine) <!-- id: 20 -->
