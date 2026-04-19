# Teknik Borç Notları

Bu doküman, ürün davranışı olarak değil, geçici uygulama detayı olarak bırakılmış teknik borçları listeler.

## 1. Dummy receipt URL fallback
- Konum: `TaskService.confirmDeliveryTask(...)`
- Ne yapıyor: Makbuz URL'i henüz yoksa akışın bloklanmaması için geçici bir dummy URL kullanıyor.
- Neden var: Teslim onay akışının, makbuz yükleme eksikliği nedeniyle tamamen durmasını önlemek için.
- Risk: Bu değer gerçek bir makbuz kaynağı gibi yorumlanmamalı; kalıcı bir iş kuralı değildir.
- Kaldırma koşulu: Makbuz yükleme zorunluluğu netleştiğinde veya teslim onayı ayrı bir doğrulama akışına bölündüğünde.

## 2. Random UUID exclude workaround
- Konum: `TaskAssignmentRedisService.createAssignmentQueueAndGetFirst(...)`
- Ne yapıyor: Aday sorgusunda zorunlu olan `excludedUserId` parametresi için geçici bir `UUID.randomUUID()` değeri kullanıyor.
- Neden var: İlk otomatik atama anında dışlanacak gerçek bir kullanıcı id'si olmadığı için repository imzasını kısa vadede karşılamak amacıyla.
- Risk: Bu değer gerçek kullanıcı kimliği değildir; yalnızca sentinel amaçlıdır ve iş kuralı olarak ele alınmamalıdır.
- Kaldırma koşulu: Repository sorgusu `null`/optional exclude parametre destekleyecek şekilde yeniden düzenlendiğinde veya ayrı bir overload eklendiğinde.

## 3. Delivery confirmation auto-complete mismatch
- Konum: `TaskService.confirmDeliveryTask(...)` ve `TaskIntegrationTest.confirmDeliveryTask_Success(...)`
- Ne yapıyor: Teslim onayı tek adımda görevi `COMPLETED` durumuna geçiriyor; test tarafındaki beklenen akış ise teslimin `DELIVERED` + `deliveryConfirmed=true` seviyesinde kalması ve tamamlamanın ayrı bir adım olarak ele alınması.
- Neden önemli: Davranış ile test/akış beklentisi aynı değilse, ileride teslim onayı ile tamamlamanın birbirine karışmasına ve audit akışında belirsizliğe yol açabilir.
- Risk: Bu fark korunursa API sözleşmesi ile testler ve ürün davranışı arasında uyumsuzluk oluşur.
- Kaldırma koşulu: Teslim onayı ve görev tamamlama akışı net biçimde tek aşamalı ya da iki aşamalı olarak standardize edildiğinde.

## 4. Genel not
- Bu maddeler yeni ürün davranışı değil, mevcut akışı bozmamak için kabul edilmiş teknik geçici çözümlerdir.
- Yeni borç eklendikçe bu dokümana kısa ve net maddeler halinde yazılmalıdır.
