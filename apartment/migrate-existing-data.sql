-- ========================================
-- 기존 데이터 마이그레이션
-- 봉담자이프라이드시티 아파트 추가 및 기존 데이터 연결
-- ========================================

-- 1. 봉담자이프라이드시티 아파트 추가 (기존 데이터용)
INSERT INTO apartments (name, code, address, is_active) VALUES
  ('봉담자이프라이드시티', 'APT004', '경기도 화성시 봉담읍', true)
ON CONFLICT (code) DO NOTHING;

-- 2. 봉담자이프라이드시티의 ID 가져오기
DO $$
DECLARE
  apt_id UUID;
BEGIN
  -- 봉담자이프라이드시티 ID 조회
  SELECT id INTO apt_id FROM apartments WHERE code = 'APT004';
  
  -- 3. 기존 데이터에 아파트 ID 연결 (apartment_id가 NULL인 모든 데이터)
  
  -- 직원 데이터
  UPDATE employees 
  SET apartment_id = apt_id 
  WHERE apartment_id IS NULL;
  
  RAISE NOTICE '직원 데이터 업데이트 완료';
  
  -- 구역 데이터
  UPDATE locations 
  SET apartment_id = apt_id 
  WHERE apartment_id IS NULL;
  
  RAISE NOTICE '구역 데이터 업데이트 완료';
  
  -- 청소 작업 데이터
  UPDATE cleaning_tasks 
  SET apartment_id = apt_id 
  WHERE apartment_id IS NULL;
  
  RAISE NOTICE '청소 작업 데이터 업데이트 완료';
  
  -- 출석 기록 데이터
  UPDATE attendance_records 
  SET apartment_id = apt_id 
  WHERE apartment_id IS NULL;
  
  RAISE NOTICE '출석 기록 데이터 업데이트 완료';
  
END $$;

-- 4. 확인 쿼리
SELECT 
  '아파트 목록' AS category,
  name AS apartment_name,
  code,
  address,
  is_active
FROM apartments
ORDER BY created_at;

-- 각 테이블별 아파트 연결 현황
SELECT 
  '직원' AS table_name,
  a.name AS apartment_name,
  COUNT(e.id) AS count
FROM employees e
LEFT JOIN apartments a ON e.apartment_id = a.id
GROUP BY a.name
ORDER BY count DESC;

SELECT 
  '구역' AS table_name,
  a.name AS apartment_name,
  COUNT(l.id) AS count
FROM locations l
LEFT JOIN apartments a ON l.apartment_id = a.id
GROUP BY a.name
ORDER BY count DESC;

SELECT 
  '청소 작업' AS table_name,
  a.name AS apartment_name,
  COUNT(c.id) AS count
FROM cleaning_tasks c
LEFT JOIN apartments a ON c.apartment_id = a.id
GROUP BY a.name
ORDER BY count DESC;

SELECT 
  '출석 기록' AS table_name,
  a.name AS apartment_name,
  COUNT(ar.id) AS count
FROM attendance_records ar
LEFT JOIN apartments a ON ar.apartment_id = a.id
GROUP BY a.name
ORDER BY count DESC;
