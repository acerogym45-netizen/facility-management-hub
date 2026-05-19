-- ========================================
-- 아파트 다중 관리 및 직원 계약기간 관리 기능 추가
-- ========================================

-- 1. 아파트 테이블 생성
CREATE TABLE IF NOT EXISTS apartments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    address TEXT,
    contact_person TEXT,
    contact_phone TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE apartments IS '카인드원이 관리하는 아파트 목록';
COMMENT ON COLUMN apartments.name IS '아파트 이름 (예: 래미안아파트)';
COMMENT ON COLUMN apartments.code IS '아파트 코드 (예: APT001)';
COMMENT ON COLUMN apartments.address IS '아파트 주소';
COMMENT ON COLUMN apartments.contact_person IS '담당자 이름';
COMMENT ON COLUMN apartments.contact_phone IS '담당자 연락처';

-- 2. 직원 테이블에 아파트 외래키 및 계약기간 추가
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS apartment_id UUID REFERENCES apartments(id),
ADD COLUMN IF NOT EXISTS contract_start DATE,
ADD COLUMN IF NOT EXISTS contract_end DATE,
ADD COLUMN IF NOT EXISTS contract_renewal_notified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS notes TEXT;

COMMENT ON COLUMN employees.apartment_id IS '소속 아파트 (외래키)';
COMMENT ON COLUMN employees.contract_start IS '계약 시작일';
COMMENT ON COLUMN employees.contract_end IS '계약 종료일';
COMMENT ON COLUMN employees.contract_renewal_notified IS '재계약 알림 발송 여부';
COMMENT ON COLUMN employees.notes IS '직원 메모 (재계약 관련 메모 등)';

-- 3. 구역 테이블에 아파트 외래키 추가
ALTER TABLE locations 
ADD COLUMN IF NOT EXISTS apartment_id UUID REFERENCES apartments(id);

COMMENT ON COLUMN locations.apartment_id IS '소속 아파트 (외래키)';

-- 4. 청소 작업 테이블에 아파트 외래키 추가 (이미 있을 수 있음)
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS apartment_id UUID REFERENCES apartments(id);

COMMENT ON COLUMN cleaning_tasks.apartment_id IS '소속 아파트 (외래키)';

-- 5. 출석 기록 테이블에 아파트 외래키 추가
ALTER TABLE attendance_records 
ADD COLUMN IF NOT EXISTS apartment_id UUID REFERENCES apartments(id);

COMMENT ON COLUMN attendance_records.apartment_id IS '소속 아파트 (외래키)';

-- 6. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_employees_apartment ON employees(apartment_id);
CREATE INDEX IF NOT EXISTS idx_employees_contract_end ON employees(contract_end);
CREATE INDEX IF NOT EXISTS idx_locations_apartment ON locations(apartment_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_apartment ON cleaning_tasks(apartment_id);
CREATE INDEX IF NOT EXISTS idx_attendance_apartment ON attendance_records(apartment_id);

-- 7. Row Level Security 설정
ALTER TABLE apartments ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기/쓰기 가능 (개발용)
CREATE POLICY "Allow all" ON apartments FOR ALL USING (true);

-- 8. 샘플 아파트 데이터 삽입 (예시)
INSERT INTO apartments (name, code, address, is_active) VALUES
  ('래미안 아파트', 'APT001', '서울시 강남구', true),
  ('힐스테이트 아파트', 'APT002', '서울시 서초구', true),
  ('자이 아파트', 'APT003', '서울시 송파구', true)
ON CONFLICT (code) DO NOTHING;

-- 9. 계약 만료 임박 직원 조회 함수 (1개월 전)
CREATE OR REPLACE FUNCTION get_contract_expiring_employees(days_before INTEGER DEFAULT 30)
RETURNS TABLE (
  id UUID,
  name TEXT,
  employee_number TEXT,
  apartment_name TEXT,
  contract_end DATE,
  days_until_expiry INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.employee_number,
    a.name AS apartment_name,
    e.contract_end,
    (e.contract_end - CURRENT_DATE) AS days_until_expiry
  FROM employees e
  LEFT JOIN apartments a ON e.apartment_id = a.id
  WHERE e.is_active = true
    AND e.contract_end IS NOT NULL
    AND e.contract_end BETWEEN CURRENT_DATE AND (CURRENT_DATE + days_before)
    AND e.contract_renewal_notified = false
  ORDER BY e.contract_end ASC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_contract_expiring_employees IS '계약 만료가 임박한 직원 목록 조회 (기본 30일 전)';

-- 10. 확인 쿼리
SELECT 
  'apartments' AS table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'apartments'
ORDER BY ordinal_position;

SELECT 
  'employees' AS table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'employees' 
AND column_name IN ('apartment_id', 'contract_start', 'contract_end', 'contract_renewal_notified', 'notes')
ORDER BY ordinal_position;
