-- 구매 요청 시스템 v1.1 - 검수 프로세스 간소화
-- 배송 완료 + 검수 완료 → 완료 (통합)

-- 1. purchases 테이블 상태 변경
-- 기존: pending, approved, rejected, delivered, completed
-- 신규: pending, approved, rejected, completed

-- purchases 테이블에 inspection_qr 컬럼 추가 (검수 전용 QR)
ALTER TABLE purchases 
ADD COLUMN IF NOT EXISTS inspection_qr TEXT UNIQUE;

-- 검수 완료 시각 추가
ALTER TABLE purchases
ADD COLUMN IF NOT EXISTS inspected_at TIMESTAMPTZ;

-- 검수자 이름 추가
ALTER TABLE purchases
ADD COLUMN IF NOT EXISTS inspected_by TEXT;

-- 기존 delivered 상태를 completed로 변경
UPDATE purchases 
SET status = 'completed' 
WHERE status = 'delivered';

-- 상태 체크 제약 조건 업데이트
ALTER TABLE purchases 
DROP CONSTRAINT IF EXISTS purchases_status_check;

ALTER TABLE purchases
ADD CONSTRAINT purchases_status_check 
CHECK (status IN ('pending', 'approved', 'rejected', 'completed'));

-- 검수 QR 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_purchases_inspection_qr ON purchases(inspection_qr);

-- purchase_qr_requests 테이블에 inspection_mode 추가
ALTER TABLE purchase_qr_requests
ADD COLUMN IF NOT EXISTS qr_type TEXT DEFAULT 'request' CHECK (qr_type IN ('request', 'inspection'));

COMMENT ON COLUMN purchases.inspection_qr IS '검수 전용 QR 코드 (승인 시 자동 생성)';
COMMENT ON COLUMN purchases.inspected_at IS '검수 완료 시각';
COMMENT ON COLUMN purchases.inspected_by IS '검수자 이름 (물품 수령자)';

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE '✅ 구매 요청 시스템 v1.1 업데이트 완료!';
  RAISE NOTICE '📦 새로운 플로우: 승인 대기 → 승인됨 → 완료';
  RAISE NOTICE '🔍 검수 전용 QR: inspection_qr 컬럼 추가';
  RAISE NOTICE '👤 검수자 추적: inspected_by, inspected_at 추가';
END $$;
