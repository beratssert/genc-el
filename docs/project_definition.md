# Proje Tanımı: Sosyal Destek ve Alışveriş Yardımlaşma Platformu

## Genel Özet
Bu proje, evinden çıkamayan yaşlı veya engelli bireyler ile onlara alışveriş desteği sağlayabilecek üniversite öğrencilerini bir araya getiren sosyal sorumluluk odaklı bir mobil/web uygulamasıdır. Proje, yerel kurumlar (Devlet/Belediye/STK) tarafından yönetilecek ve öğrencileri burs ile teşvik edecektir.

## Aktörler (Kullanıcı Rolleri)

### 1. Yaşlı / Engelli Birey (Hizmet Alan)
- **Kayıt:** Kurum tarafından sisteme kaydedilir.
- **İşlevler:**
    - Alışveriş listesi oluşturma.
    - "Öğrenci Çağır" butonu ile talep oluşturma.
    - Gelen öğrenciyi ve teslim edilen parayı onaylama.
    - Alışveriş tamamlandığında teslimatı ve para üstünü onaylama.

### 2. Öğrenci (Gönüllü / Hizmet Veren)
- **Kayıt:** Kurum tarafından sisteme kaydedilir.
- **İşlevler:**
    - Gelen çağrı bildirimlerini görme (Konum ve Liste detayları).
    - Çağrıyı kabul etme veya reddetme.
    - Alışveriş sürecini yönetme (Başlangıç, Ödeme alma, Alışveriş yapma, Teslimat).
    - Alışveriş fişini sisteme yükleme.
    - Tamamlanan görev sayısına göre burs yönetimi (Kurum takibi).

### 3. Kurum (Yönetici)
- **İşlevler:**
    - Bölgesindeki yaşlı/engelli ve öğrenci kayıtlarını yönetme (CRUD).
    - Öğrencilerin aylık performanslarını (tamamlanan görev sayısı) görüntüleme.
    - Performansa dayalı burs hesaplamaları ve takibi.

## Temel İş Akışı (Senaryo)

1. **Talep Oluşturma:** Yaşlı birey (Ayşe Teyze) uygulamaya girer, alışveriş listesini (Ekmek, Yumurta) yazar ve çağrı butonuna basar.
2. **Eşleşme ve Bildirim:** Sistem, yakındaki uygun öğrencileri (Ahmet) belirler ve bildirim gönderir.
    - *Zaman Aşımı / Red:* Ahmet reddederse veya süresi dolarsa (10dk), çağrı bir sonraki öğrenciye (Berat) düşer.
3. **Görev Kabulü:** Berat çağrıyı kabul eder ve Ayşe Teyze'nin konumuna gider.
4. **Alışveriş Öncesi Onay:** 
    - Berat eve varır.
    - Ayşe Teyze sisteme verilen parayı (100 TL) ve listeyi son kez girer/onaylar.
    - Berat bu bilgileri sistemden onaylar ve parayı teslim alır.
5. **Alışveriş Süreci:** Berat markete gider, ürünleri alır.
6. **Teslimat ve Kapanış:**
    - Berat eve döner, ürünleri ve para üstünü (10 TL) teslim eder.
    - Berat sisteme fiş fotoğrafını yükler, para üstü miktarını girer ve görevi "Tamamlandı" olarak işaretler.
    - Ayşe Teyze sistemden teslimatı ve para üstünü onaylar.
7. **Puanlama/Kayıt:** İşlem başarıyla kapanır, Berat'ın hanesine +1 görev eklenir.

## Teknik Gereksinimler (Ön Hazırlık)
- **Mobil Uygulama:** Öğrenci ve Yaşlı bireyler için (Konum takibi, Bildirimler, Kamera erişimi).
- **Web Paneli:** Kurumlar için yönetim paneli.
- **Backend:** Gerçek zamanlı bildirimler (WebSocket/Push Notification), Konum tabanlı sorgular (Geospatial queries), Dosya depolama (Fiş fotoğrafları).

## Teknoloji Yığını (Tech Stack)
- **Backend:** Spring Boot (Java) + Redis (Cache & Queue)
- **Frontend (Mobil):** Flutter (Dart)
- **Veritabanı:** PostgreSQL
- **Harita/Konum:** Google Maps API veya OpenStreetMap
- **Bildirim:** Firebase Cloud Messaging (FCM)
