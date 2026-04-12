import 'dart:io' show Platform;

/// Backend API endpointleri.
/// Base URL Dio'da zaten tanımlı, buradaki path'ler relative.
///
/// Android emülatörde: 10.0.2.2
/// Android fiziksel cihaz: bilgisayarın yerel ağ IP'si
/// iOS simülatör / macOS: localhost
class ApiUrl {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Fiziksel cihaz → bilgisayarın LAN IP'si
      // Emülatör kullanıyorsan bunu '10.0.2.2' yap
      return 'http://172.20.10.2:8080';
    }
    // iOS / macOS / web → localhost
    return 'http://localhost:8080';
  }

  // ─── Auth ───────────────────────────────────────────
  static const String userLogin = '/api/v1/user/login';
  static const String institutionLogin = '/api/v1/institution/login';

  // ─── User ───────────────────────────────────────────
  /// POST  — kurum kullanıcısı oluştur (INSTITUTION_ADMIN)
  /// GET   — kurum kullanıcılarını listele (INSTITUTION_ADMIN)
  static const String users = '/api/v1/user';

  /// GET   — profilimi getir
  /// PUT   — profilimi güncelle
  /// DELETE — hesabımı dondur
  static const String myProfile = '/api/v1/user/me';

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

  /// PUT   — görevi üzerine al → /api/v1/tasks/{id}/assign
  static String assignTask(String taskId) => '/api/v1/tasks/$taskId/assign';

  /// PUT   — alışverişe başla → /api/v1/tasks/{id}/start
  static String startTask(String taskId) => '/api/v1/tasks/$taskId/start';

  /// PUT   — teslim et → /api/v1/tasks/{id}/deliver
  static String deliverTask(String taskId) => '/api/v1/tasks/$taskId/deliver';

  /// PUT   — tamamla → /api/v1/tasks/{id}/complete
  static String completeTask(String taskId) => '/api/v1/tasks/$taskId/complete';

  /// PUT   — iptal et → /api/v1/tasks/{id}/cancel
  static String cancelTask(String taskId) => '/api/v1/tasks/$taskId/cancel';

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
