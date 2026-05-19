-- 구매 요청 시스템 v1.2 - 직원 QR 통합
-- 직원이 자기 QR로 출근 체크하는 페이지에서 구매 요청도 관리할 수 있도록 개선

-- 1. purchases 테이블에 직원 ID 및 검수 메모 컬럼 추가
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS requester_employee_id UUID REFERENCES employees(id);
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS inspection_notes TEXT;

-- 2. 인덱스 추가 (검색 성능 향상)
CREATE INDEX IF NOT EXISTS idx_purchases_requester_employee_id ON purchases(requester_employee_id);
CREATE INDEX IF NOT EXISTS idx_purchases_status_requester ON purchases(status, requester_employee_id);

-- 3. 기존 데이터 마이그레이션 (requester_name으로 employee_id 매칭)
UPDATE purchases p
SET requester_employee_id = e.id
FROM employees e
WHERE p.requester_name = e.name 
  AND p.requester_employee_id IS NULL;

-- 4. 컬럼 설명
COMMENT ON COLUMN purchases.requester_employee_id IS '요청자 직원 ID (employees 테이블 참조)';
COMMENT ON COLUMN purchases.inspection_notes IS '검수 메모 (직원이 검수 시 작성)';

-- 완료 메시지
SELECT '✅ 구매 요청 시스템 v1.2 업데이트 완료!' as message;
SELECT '📱 직원 QR 페이지에서 구매 요청 관리 가능' as feature;
SELECT '🔍 검수 대기 항목 자동 표시' as feature;
