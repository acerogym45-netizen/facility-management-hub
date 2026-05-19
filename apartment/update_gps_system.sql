-- ========================================
-- GPS 위치 기반 인증 시스템 v2.0
-- ========================================

-- 1️⃣ apartments 테이블에 GPS 좌표 추가
ALTER TABLE apartments 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS allowed_radius_meters INTEGER DEFAULT 1000;

COMMENT ON COLUMN apartments.location_lat IS '단지 중심 위도';
COMMENT ON COLUMN apartments.location_lng IS '단지 중심 경도';
COMMENT ON COLUMN apartments.allowed_radius_meters IS '허용 반경 (미터, 기본값 1000m)';

-- 2️⃣ attendance 테이블에 GPS 정보 추가
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS gps_accuracy FLOAT,
ADD COLUMN IF NOT EXISTS distance_from_workplace FLOAT,
ADD COLUMN IF NOT EXISTS is_suspicious BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS suspicious_reason TEXT;

COMMENT ON COLUMN attendance.location_lat IS '기록 시 직원 위도';
COMMENT ON COLUMN attendance.location_lng IS '기록 시 직원 경도';
COMMENT ON COLUMN attendance.gps_accuracy IS 'GPS 정확도 (미터)';
COMMENT ON COLUMN attendance.distance_from_workplace IS '근무지로부터 거리 (미터)';
COMMENT ON COLUMN attendance.is_suspicious IS '의심스러운 기록 여부';
COMMENT ON COLUMN attendance.suspicious_reason IS '의심 사유';

-- 3️⃣ work_photos 테이블에 GPS 정보 추가
ALTER TABLE work_photos 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS gps_accuracy FLOAT;

COMMENT ON COLUMN work_photos.location_lat IS '사진 촬영 위도';
COMMENT ON COLUMN work_photos.location_lng IS '사진 촬영 경도';
COMMENT ON COLUMN work_photos.gps_accuracy IS 'GPS 정확도 (미터)';

-- 4️⃣ employees 테이블에 기기 인증 컬럼 추가
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS device_fingerprint TEXT,
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS access_token TEXT UNIQUE;

COMMENT ON COLUMN employees.device_fingerprint IS '기기 고유 식별자';
COMMENT ON COLUMN employees.last_login_at IS '마지막 로그인 시각';
COMMENT ON COLUMN employees.access_token IS '자동 로그인 토큰';

-- 5️⃣ 기존 단지 데이터에 GPS 좌표 추가 (예시)
-- 실제 좌표는 Google Maps에서 확인 필요

-- 봉담자이프라이드시티
UPDATE apartments SET
  location_lat = 37.2157891,
  location_lng = 127.0528374,
  allowed_radius_meters = 1000
WHERE code = 'BJD001';

-- 용인동백센트럴
UPDATE apartments SET
  location_lat = 37.2889456,
  location_lng = 127.1723845,
  allowed_radius_meters = 1000
WHERE code = 'YDB002';

-- 수원영통자이
UPDATE apartments SET
  location_lat = 37.2471234,
  location_lng = 127.0768123,
  allowed_radius_meters = 1000
WHERE code = 'SYT003';

-- 평택고덕국제신도시
UPDATE apartments SET
  location_lat = 36.9912345,
  location_lng = 127.0856789,
  allowed_radius_meters = 1000
WHERE code = 'PGD004';

-- 기타 단지 (임시 좌표)
UPDATE apartments SET
  location_lat = 37.5665,
  location_lng = 126.9780,
  allowed_radius_meters = 1000
WHERE code = 'ETC999' AND location_lat IS NULL;

-- 6️⃣ 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_attendance_location ON attendance(location_lat, location_lng);
CREATE INDEX IF NOT EXISTS idx_attendance_suspicious ON attendance(is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX IF NOT EXISTS idx_employees_device ON employees(device_fingerprint);
CREATE INDEX IF NOT EXISTS idx_employees_token ON employees(access_token);

-- 7️⃣ 의심스러운 활동 로그 테이블 생성
CREATE TABLE IF NOT EXISTS suspicious_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id),
  activity_type TEXT NOT NULL, -- 'gps_spoofing', 'fast_travel', 'low_accuracy' 등
  reason TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  distance_diff FLOAT,
  time_diff FLOAT,
  speed_kmh FLOAT,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  is_resolved BOOLEAN DEFAULT FALSE,
  admin_notes TEXT
);

COMMENT ON TABLE suspicious_activities IS '의심스러운 위치 활동 로그';

CREATE INDEX IF NOT EXISTS idx_suspicious_activities_employee ON suspicious_activities(employee_id);
CREATE INDEX IF NOT EXISTS idx_suspicious_activities_unresolved ON suspicious_activities(is_resolved) WHERE is_resolved = FALSE;

-- 8️⃣ RLS 정책 추가
ALTER TABLE suspicious_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all users to insert suspicious activities"
  ON suspicious_activities FOR INSERT TO authenticated, anon WITH CHECK (true);

CREATE POLICY "Allow all users to view suspicious activities"
  ON suspicious_activities FOR SELECT TO authenticated, anon USING (true);

-- 9️⃣ 확인 쿼리
SELECT 
  code,
  name,
  location_lat,
  location_lng,
  allowed_radius_meters
FROM apartments
WHERE location_lat IS NOT NULL
ORDER BY code;

SELECT '✅ GPS 위치 기반 인증 시스템 v2.0 업데이트 완료!' AS message;
SELECT '📍 모든 단지 반경: 1000m (1km)' AS info;
SELECT '🎯 시범 운영 준비 완료' AS status;
