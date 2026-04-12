# Test Dokümantasyonu

Bu projede kapsamlı otomatik testler CI/Docker pipeline'da çalıştırılır. Testler başarısız olursa deploy yapılmaz.

## Test Yapısı

### 1. Unit Testler (Service Katmanı)
- `InstitutionServiceTest` – Kurum CRUD mantığı
- `UserServiceTest` – Kullanıcı oluşturma, liste filtreleme, validasyon
- `AuthServiceTest` – userLogin / institutionLogin, hatalı giriş senaryoları

### 2. Integration Testler (Controller Katmanı)
- `InstitutionControllerIntegrationTest` – API endpoint’leri (POST/GET institution, login)
- `UserControllerIntegrationTest` – User login, create, list (JWT/auth simülasyonu ile)
- `RepositoryIntegrationTest` – JPA entity’ler ve repository’ler (Institution, User, Task, TaskLog, BursaryHistory)

### 3. Redis Integration Testler (Service + Gerçek Redis)
- `TaskAssignmentRedisServiceIntegrationTest` – Gerçek Redis container ile kuyruk/pending key davranışı
- Testcontainers ile `redis:7-alpine` ayağa kaldırılır, `TaskAssignmentRedisService` uçtan uca doğrulanır

### 4. Test Konfigürasyonu
- **Profil:** `test`
- **Veritabanı:** H2 in-memory (PostgreSQL uyumlu mod)
- **Redis:** Test ortamında devre dışı (`RedisAutoConfiguration` exclude)
- **Redis integration test:** `test` profili kullanılmaz; H2 + gerçek Redis Testcontainers ile çalışır

## Komutlar

```bash
# Tüm testleri çalıştır
cd backend && mvn test

# Sadece Redis integration testini çalıştır
cd backend && mvn -Dtest=TaskAssignmentRedisServiceIntegrationTest test

# Test + paketleme (CI’da kullanılan)
mvn clean verify
```

## CI / Docker

### GitHub Actions
- Push/PR’da `main`, `master`, `develop` branch’lerinde otomatik çalışır
- `mvn clean verify` ile testler koşar
- main/master’da Docker image build edilir

### Docker Build
- `docker build` sırasında testler koşar
- Testler başarısız olursa image oluşturulmaz

```bash
docker build -t genc-el-backend ./backend

# Tüm sistemi Docker Compose ile smoke test et
./scripts/docker-smoke-test.sh
```

### Docker Compose Smoke Test
- Backend + PostgreSQL + Redis birlikte ayağa kalkar.
- `POST /api/v1/admin/login` endpoint'i ile canlı akış doğrulanır.
- Login cevabında `token` döndüğü doğrulanır.
- Test sonunda container'lar otomatik kapatılır (`docker compose down -v`).

## Yeni Test Eklerken

1. **Unit test:** `@ExtendWith(MockitoExtension.class)`, mock’lar ile
2. **Integration test:** `@SpringBootTest` + `@AutoConfigureMockMvc` + `@Transactional`
3. **Controller test:** `MockMvc`, `@WithMockUser` veya `user().roles()` ile yetkilendirme
