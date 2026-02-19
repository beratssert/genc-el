# Gen-El Projesi Geliştirme Yol Haritası

Bu belge, uygulamanın tamamlanması için gereken adımları mantıksal bir sırayla sunar.

## Faz 1: Altyapı ve Servis Katmanı (Core Infrastructure)
Repo ve modeller tanımlandı, ancak gerçek dünya kullanımı için altyapının güçlendirilmesi gerekir.

1.  **Network Servisi Oluşturulması**:
    - `Dio` veya `http` paketi ile merkezi bir API servisi.
    - JWT (Token) yönetimi ve otomatik logout mekanizması.
2.  **Repository Implementasyonları**:
    - `AuthRepo`, `UserRepo`, `TaskRepo` ve `InstitutionRepo` içindeki `UnimplementedError`ların gerçek servis çağrılarına dönüştürülmesi.
3.  **Local Storage**:
    - Kullanıcı tercihlerini veya token'ı saklamak için `flutter_secure_storage` veya `shared_preferences` entegrasyonu.

## Faz 2: Temel Kullanıcı Deneyimi (UI/UX Foundation)
Uygulamanın görsel kimliği ve navigasyonu.

1.  **Design System ve Temalandırma**:
    - Renk paleti, tipografi ve ortak widgetlar (Butonlar, TextFieldlar).
2.  **Navigasyon Yapısı**:
    - `GoRouter` veya `AutoRouter` ile rol tabanlı (Öğrenci/Yaşlı/Kurum) yönlendirme.
3.  **Auth Akışı**:
    - Login ve Şifre Yenileme ekranlarının tasarımı.

## Faz 3: Ana Fonksiyonlar (Feature Implementation)
Uygulamanın asıl değerini yaratan özellikler.

1.  **Yaşlı/Engelli Modülü**:
    - Yeni alışveriş isteği oluşturma ekranı.
    - Aktif görev takibi ve onay mekanizması.
2.  **Öğrenci Modülü**:
    - Yakındaki görevleri listeleme (Harita veya Liste görünümü).
    - Görev kabul etme, alışveriş süreci (Fiş yükleme) ve tamamlama adımları.
3.  **Hakediş ve Profil**:
    - Öğrenci için aylık hakediş (burs) görünümü.
    - Kullanıcı profil düzenleme.

## Faz 4: Kurumsal Yönetim (Institution Management)
Kurum yetkilileri için tasarlanmış yönetim paneli (Mobil veya Web).

1.  **Kullanıcı Yönetimi**:
    - Yeni kullanıcı kaydı ve listeleme.
2.  **İstatistik ve Finans**:
    - Kurum istatistikleri dashboardu.
    - Burs ödeme onayı ve hesaplama tetikleme.

## Faz 5: İyileştirme ve Yayın (Polishing & Deployment)
1.  **Push Notifications**: Görev eşleşmeleri ve onaylar için bildirim altyapısı.
2.  **Hata Yönetimi ve Logging**: Kullanıcıya dost hata mesajları.
3.  **Testler**: Kritik akışlar için Unit ve Integration testleri.
4.  **Cihaz Testleri**: Android ve iOS fiziksel cihazlarda performans kontrolü.
