-- #############################################################
-- 1. TEMİZLİK (İlişki sırasına göre)
-- #############################################################
DROP TABLE IF EXISTS task_log;
DROP TABLE IF EXISTS task;
DROP TABLE IF EXISTS bursary_history;
DROP TABLE IF EXISTS "user";
DROP TABLE IF EXISTS institution;

-- #############################################################
-- 2. TABLO OLUŞTURMA (VERİ BÜTÜNLÜĞÜ KORUNMUŞ)
-- #############################################################

CREATE TABLE institution (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    region VARCHAR(255),
    contact_info TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institution(id) ON DELETE SET NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('STUDENT', 'ELDERLY', 'INSTITUTION_ADMIN')),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE,
    iban VARCHAR(34),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bursary_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    year INTEGER,
    month INTEGER CHECK (month BETWEEN 1 AND 12),
    completed_task_count INTEGER DEFAULT 0,
    calculated_amount DOUBLE PRECISION DEFAULT 0.0,
    is_paid BOOLEAN DEFAULT FALSE,
    payment_date TIMESTAMP,
    transaction_reference VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID REFERENCES "user"(id) ON DELETE RESTRICT,
    volunteer_id UUID REFERENCES "user"(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'DELIVERED', 'COMPLETED', 'CANCELLED')),
    shopping_list JSONB,
    note TEXT,
    total_amount_given DOUBLE PRECISION,
    change_amount DOUBLE PRECISION,
    receipt_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES task(id) ON DELETE CASCADE,
    action VARCHAR(50), -- CREATE, ASSIGNED, vb.
    user_id UUID REFERENCES "user"(id) ON DELETE SET NULL,
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- #############################################################
-- 3. VERİ EKLEME (KURUMLAR VE TÜM KULLANICILAR)
-- #############################################################

-- KURUMLAR
INSERT INTO institution (id, name, region, contact_info) VALUES 
('11111111-1111-1111-1111-111111111111', 'Ankara Yardımlaşma Vakfı', 'İç Anadolu', '03121112233'),
('22222222-2222-2222-2222-222222222222', 'İstanbul Eğitim Derneği', 'Marmara', '02121112233'),
('33333333-3333-3333-3333-333333333333', 'İzmir İyilik Cemiyeti', 'Ege', '02321112233');

-- KURUM ADMİNLERİ EKLEME
INSERT INTO "user" (institution_id, role, first_name, last_name, phone_number, email, password_hash, address, is_active) VALUES 
('11111111-1111-1111-1111-111111111111', 'INSTITUTION_ADMIN', 'Bülent', 'Yönetici', '03129990001', 'admin@ankara.com', 'admin_hash', 'Vakıf Merkezi Ankara', TRUE),
('22222222-2222-2222-2222-222222222222', 'INSTITUTION_ADMIN', 'Sibel', 'Yılmaz', '02129990001', 'admin@istanbul.com', 'admin_hash', 'Dernek Merkezi İstanbul', TRUE),
('33333333-3333-3333-3333-333333333333', 'INSTITUTION_ADMIN', 'Murat', 'Kaya', '02329990001', 'admin@izmir.com', 'admin_hash', 'Cemiyet Merkezi İzmir', TRUE);

-- ANKARA: 5 Öğrenci + 5 Yaşlı
INSERT INTO "user" (institution_id, role, first_name, last_name, phone_number, email, password_hash, address, latitude, longitude, is_active, iban) VALUES 
('11111111-1111-1111-1111-111111111111', 'STUDENT', 'Ahmet', 'Yılmaz', '555001', 'ahmet@ankara.com', 'hash', 'Çankaya No 1', 39.9208, 32.8541, TRUE, 'TR0101'),
('11111111-1111-1111-1111-111111111111', 'STUDENT', 'Ayşe', 'Demir', '555002', 'ayse@ankara.com', 'hash', 'Kızılay No 2', 39.9255, 32.8510, TRUE, 'TR0102'),
('11111111-1111-1111-1111-111111111111', 'STUDENT', 'Mehmet', 'Kaya', '555003', 'mehmet@ankara.com', 'hash', 'Bahçeli No 3', 39.9167, 32.8333, TRUE, 'TR0103'),
('11111111-1111-1111-1111-111111111111', 'STUDENT', 'Fatma', 'Şahin', '555004', 'fatma@ankara.com', 'hash', 'Emek No 4', 39.9100, 32.8200, TRUE, 'TR0104'),
('11111111-1111-1111-1111-111111111111', 'STUDENT', 'Can', 'Yıldız', '555005', 'can@ankara.com', 'hash', 'Dikmen No 5', 39.8600, 32.8400, TRUE, 'TR0105'),
('11111111-1111-1111-1111-111111111111', 'ELDERLY', 'Hüseyin', 'Amca', '532001', 'huseyin@ankara.com', 'hash', 'Yıldız Apt', 39.8800, 32.8600, TRUE, NULL),
('11111111-1111-1111-1111-111111111111', 'ELDERLY', 'Emine', 'Teyze', '532002', 'emine@ankara.com', 'hash', 'Ayrancı', 39.8900, 32.8500, TRUE, NULL),
('11111111-1111-1111-1111-111111111111', 'ELDERLY', 'Yusuf', 'Dede', '532003', 'yusuf@ankara.com', 'hash', 'Beşevler', 39.9300, 32.8100, TRUE, NULL),
('11111111-1111-1111-1111-111111111111', 'ELDERLY', 'Zeynep', 'Nene', '532004', 'zeynep@ankara.com', 'hash', 'GOP', 39.8970, 32.8752, TRUE, NULL),
('11111111-1111-1111-1111-111111111111', 'ELDERLY', 'Ali', 'Bey', '532005', 'aliriza@ankara.com', 'hash', 'Mamak', 39.9200, 32.9000, TRUE, NULL);

-- İSTANBUL: 5 Öğrenci + 5 Yaşlı
INSERT INTO "user" (institution_id, role, first_name, last_name, phone_number, email, password_hash, address, latitude, longitude, is_active, iban) VALUES 
('22222222-2222-2222-2222-222222222222', 'STUDENT', 'Burak', 'Öztürk', '555011', 'burak@istanbul.com', 'hash', 'Kadıköy', 40.9901, 29.0200, TRUE, 'TR0201'),
('22222222-2222-2222-2222-222222222222', 'STUDENT', 'Selin', 'Aydın', '555012', 'selin@istanbul.com', 'hash', 'Beşiktaş', 41.0422, 29.0074, TRUE, 'TR0202'),
('22222222-2222-2222-2222-222222222222', 'STUDENT', 'Arda', 'Bulut', '555013', 'arda@istanbul.com', 'hash', 'Şişli', 41.0600, 28.9800, TRUE, 'TR0203'),
('22222222-2222-2222-2222-222222222222', 'STUDENT', 'Merve', 'Koç', '555014', 'merve@istanbul.com', 'hash', 'Üsküdar', 41.0200, 29.0100, TRUE, 'TR0204'),
('22222222-2222-2222-2222-222222222222', 'STUDENT', 'Deniz', 'Sarı', '555015', 'deniz@istanbul.com', 'hash', 'Fatih', 41.0100, 28.9400, TRUE, 'TR0205'),
('22222222-2222-2222-2222-222222222222', 'ELDERLY', 'İsmet', 'Bey', '532011', 'ismet@istanbul.com', 'hash', 'Moda Sahil', 40.9800, 29.0300, TRUE, NULL),
('22222222-2222-2222-2222-222222222222', 'ELDERLY', 'Müzeyyen', 'Hanım', '532012', 'muzeyyen@istanbul.com', 'hash', 'Nişantaşı', 41.0500, 28.9900, TRUE, NULL),
('22222222-2222-2222-2222-222222222222', 'ELDERLY', 'Osman', 'Amca', '532013', 'osman@istanbul.com', 'hash', 'Beylerbeyi', 41.0400, 29.0400, TRUE, NULL),
('22222222-2222-2222-2222-222222222222', 'ELDERLY', 'Fikriye', 'Teyze', '532014', 'fikriye@istanbul.com', 'hash', 'Bakırköy', 40.9700, 28.8700, TRUE, NULL),
('22222222-2222-2222-2222-222222222222', 'ELDERLY', 'Süleyman', 'Dede', '532015', 'suleyman@istanbul.com', 'hash', 'Sarıyer', 41.1600, 29.0500, TRUE, NULL);

-- İZMİR: 5 Öğrenci + 5 Yaşlı
INSERT INTO "user" (institution_id, role, first_name, last_name, phone_number, email, password_hash, address, latitude, longitude, is_active, iban) VALUES 
('33333333-3333-3333-3333-333333333333', 'STUDENT', 'Ege', 'Mavi', '555021', 'ege@izmir.com', 'hash', 'Karşıyaka', 38.4550, 27.1100, TRUE, 'TR0301'),
('33333333-3333-3333-3333-333333333333', 'STUDENT', 'Aslı', 'Yeşil', '555022', 'asli@izmir.com', 'hash', 'Bornova', 38.4600, 27.2100, TRUE, 'TR0302'),
('33333333-3333-3333-3333-333333333333', 'STUDENT', 'Kaan', 'Kara', '555023', 'kaan@izmir.com', 'hash', 'Konak', 38.4100, 27.1200, TRUE, 'TR0303'),
('33333333-3333-3333-3333-333333333333', 'STUDENT', 'Pınar', 'Ak', '555024', 'pinar@izmir.com', 'hash', 'Buca', 38.3900, 27.1600, TRUE, 'TR0304'),
('33333333-3333-3333-3333-333333333333', 'STUDENT', 'Ozan', 'Şen', '555025', 'ozan@izmir.com', 'hash', 'Göztepe', 38.3900, 27.0800, TRUE, 'TR0305'),
('33333333-3333-3333-3333-333333333333', 'ELDERLY', 'Hikmet', 'Amca', '532021', 'hikmet@izmir.com', 'hash', 'Bostanlı', 38.4500, 27.1000, TRUE, NULL),
('33333333-3333-3333-3333-333333333333', 'ELDERLY', 'Leman', 'Teyze', '532022', 'leman@izmir.com', 'hash', 'Alsancak', 38.4300, 27.1400, TRUE, NULL),
('33333333-3333-3333-3333-333333333333', 'ELDERLY', 'Nuri', 'Dede', '532023', 'nuri@izmir.com', 'hash', 'Balçova', 38.3800, 27.0500, TRUE, NULL),
('33333333-3333-3333-3333-333333333333', 'ELDERLY', 'Nebahat', 'Nene', '532024', 'nebahat@izmir.com', 'hash', 'Urla', 38.3200, 26.7600, TRUE, NULL),
('33333333-3333-3333-3333-333333333333', 'ELDERLY', 'Remzi', 'Bey', '532025', 'remzi@izmir.com', 'hash', 'Çeşme', 38.3200, 26.3000, TRUE, NULL);

-- #############################################################
-- 4. BURS, GÖREV VE LOGLAR
-- #############################################################

-- Burs Geçmişi
INSERT INTO bursary_history (student_id, year, month, completed_task_count, calculated_amount, is_paid, payment_date, transaction_reference) VALUES 
((SELECT id FROM "user" WHERE email = 'ahmet@ankara.com'), 2024, 1, 4, 2000.0, TRUE, '2024-01-31 10:00:00', 'ANK-TX-001'),
((SELECT id FROM "user" WHERE email = 'ayse@ankara.com'), 2024, 1, 2, 1000.0, TRUE, '2024-01-31 11:00:00', 'ANK-TX-002'),
((SELECT id FROM "user" WHERE email = 'burak@istanbul.com'), 2024, 1, 5, 2500.0, TRUE, '2024-01-31 12:00:00', 'IST-TX-001'),
((SELECT id FROM "user" WHERE email = 'selin@istanbul.com'), 2024, 1, 3, 1500.0, FALSE, NULL, NULL),
((SELECT id FROM "user" WHERE email = 'ege@izmir.com'), 2024, 1, 1, 500.0, FALSE, NULL, NULL);

-- Görevler
INSERT INTO task (id, requester_id, volunteer_id, status, shopping_list, note, total_amount_given, change_amount, receipt_image_url) VALUES 
('10000000-0000-0000-0000-000000000001', (SELECT id FROM "user" WHERE email = 'huseyin@ankara.com'), (SELECT id FROM "user" WHERE email = 'ahmet@ankara.com'), 'COMPLETED', '{"items": [{"name": "Ekmek", "qty": 2}]}', 'Taze olsun.', 100.0, 45.5, 'https://receipt.url'),
('20000000-0000-0000-0000-000000000002', (SELECT id FROM "user" WHERE email = 'ismet@istanbul.com'), (SELECT id FROM "user" WHERE email = 'burak@istanbul.com'), 'IN_PROGRESS', '{"items": [{"name": "İlaç"}]}', 'Acil.', NULL, NULL, NULL),
('30000000-0000-0000-0000-000000000003', (SELECT id FROM "user" WHERE email = 'hikmet@izmir.com'), NULL, 'PENDING', '{"items": [{"name": "Gazete"}]}', 'Hürriyet.', NULL, NULL, NULL);

-- Loglar
INSERT INTO task_log (task_id, action, user_id, details) VALUES 
('10000000-0000-0000-0000-000000000001', 'CREATED', (SELECT id FROM "user" WHERE email = 'huseyin@ankara.com'), 'İhtiyaç listesi oluşturuldu.'),
('10000000-0000-0000-0000-000000000001', 'ASSIGNED', (SELECT id FROM "user" WHERE email = 'ahmet@ankara.com'), 'Ahmet görevi üstlendi.'),
('20000000-0000-0000-0000-000000000002', 'CREATED', (SELECT id FROM "user" WHERE email = 'ismet@istanbul.com'), 'İlaç yardımı istendi.');