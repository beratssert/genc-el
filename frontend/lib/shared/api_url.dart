import 'dart:io' show Platform;

/// Backend API endpointleri.
/// Base URL Dio'da zaten tanımlı, buradaki path'ler relative.
///
/// Android emülatörde: 10.0.2.2
/// Android fiziksel cihaz: bilgisayarın yerel ağ IP'si
/// iOS simülatör / macOS: localhost
class ApiUrl {
  // Bilgisayarınızın yerel ağdaki IP adresi (Fiziksel cihazlar için)
  // Mac Terminal'den 'ipconfig getifaddr en0' komutu ile öğrenebilirsiniz.
  static const String _serverIp = '192.168.1.106';

  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      // Eğer simülatör/emülatör değilse IP kullan, değilse localhost/10.0.2.2
      // Not: iOS fiziksel cihazda localhost çalışmaz, IP gereklidir.
      bool isEmulator = false; // Basitleştirmek için direkt IP kullanıyoruz

      // Geliştirme ortamına göre burayı switch edebilirsiniz:
      // return 'http://localhost:8080'; // Simulator
      return 'http://$_serverIp:8080'; // Physical Device
    }
    return 'http://localhost:8080';
  }

  static String get wsUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ws://$_serverIp:8080/ws/websocket';
    }
    return 'ws://localhost:8080/ws/websocket';
  }

  // ─── Auth ───────────────────────────────────────────
  static const String userLogin = '/api/v1/user/login';
  static const String institutionLogin = '/api/v1/institution/login';

  // ─── User ───────────────────────────────────────────
  /// POST  — kurum kullanıcısı oluştur (INSTITUTION_ADMIN)
  /// GET   — kurum kullanıcılarını listele (INSTITUTION_ADMIN)
  static const String users = '/api/v1/user';

  static String userById(String id) => '/api/v1/user/$id';
  static String userHistory(String id) => '/api/v1/user/$id/history';

  /// GET   — profilimi getir
  /// PUT   — profilimi güncelle
  /// DELETE — hesabımı dondur
  static const String myProfile = '/api/v1/user/me';

  /// PUT   — konumumu güncelle
  static const String myLocation = '/api/v1/user/me/location';

  // ─── Institution ────────────────────────────────────
  static const String institution = '/api/v1/institution';
  static const String myInstitution = '/api/v1/institution/me';

  // ─── Tasks ──────────────────────────────────────────
  /// POST  — yeni görev oluştur (ELDERLY)
  static const String tasks = '/api/v1/tasks';

  /// GET   — bekleyen görevleri listele
  static const String pendingTasks = '/api/v1/tasks/pending';

  /// GET   — görevlerimi listele
  static const String myTasks = '/api/v1/tasks/my-tasks';

  /// GET   — yakındaki görevler → /api/v1/tasks/nearby
  static const String nearbyTasks = '/api/v1/tasks/nearby';

  /// GET   — aktif görevimi getir → /api/v1/tasks/my-active-task
  static const String myActiveTask = '/api/v1/tasks/my-active-task';

  /// PUT   — görevi üzerine al → /api/v1/tasks/{id}/assign
  static String assignTask(String taskId) => '/api/v1/tasks/$taskId/assign';

  /// PUT   — görevi reddet → /api/v1/tasks/{id}/reject
  static String rejectTask(String taskId) => '/api/v1/tasks/$taskId/reject';

  /// PUT   — başlangıcı onayla → /api/v1/tasks/{id}/confirm-start
  static String confirmStartTask(String taskId) =>
      '/api/v1/tasks/$taskId/confirm-start';

  /// PUT   — alışverişe başla → /api/v1/tasks/{id}/start
  static String startTask(String taskId) => '/api/v1/tasks/$taskId/start';

  /// PUT   — teslimat onayla → /api/v1/tasks/{id}/confirm-end
  static String confirmEndTask(String taskId) =>
      '/api/v1/tasks/$taskId/confirm-end';

  /// PUT   — teslim et → /api/v1/tasks/{id}/deliver
  static String deliverTask(String taskId) => '/api/v1/tasks/$taskId/deliver';

  /// PUT   — tamamla → /api/v1/tasks/{id}/complete
  static String completeTask(String taskId) => '/api/v1/tasks/$taskId/complete';

  /// PUT   — iptal et → /api/v1/tasks/{id}/cancel
  static String cancelTask(String taskId) => '/api/v1/tasks/$taskId/cancel';

  /// POST  — makbuz yükle → /api/v1/tasks/{id}/receipt/upload
  static String uploadReceipt(String taskId) =>
      '/api/v1/tasks/$taskId/receipt/upload';

  // ─── Dashboard ──────────────────────────────────────
  static const String dashboardStats = '/api/v1/dashboard/stats';

  // ─── Bursary ────────────────────────────────────────
  /// GET   — kendi burs geçmişim (STUDENT)
  static const String myBursaries = '/api/v1/bursaries/me';

  /// GET   — kurum bursları (INSTITUTION_ADMIN) — ?year=&month=
  static const String institutionBursaries = '/api/v1/bursaries/institution';

  /// POST  — burs hesapla (INSTITUTION_ADMIN)
  static const String calculateBursaries = '/api/v1/bursaries/calculate';

  /// PUT   — burs ödendi işaretle → /api/v1/bursaries/{id}/pay
  static String payBursary(String bursaryId) =>
      '/api/v1/bursaries/$bursaryId/pay';
}
