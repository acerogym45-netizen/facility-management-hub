-- =====================================================
-- 휴가 승인 프로세스 추가
-- =====================================================
-- 이 스크립트는 기존 vacations 테이블에 승인 관련 컬럼을 추가합니다.

-- 1. 승인 상태 컬럼 추가
ALTER TABLE public.vacations
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS approved_by TEXT,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_vacations_status ON public.vacations(status);
CREATE INDEX IF NOT EXISTS idx_vacations_employee_status ON public.vacations(employee_id, status);
CREATE INDEX IF NOT EXISTS idx_vacations_apartment_status ON public.vacations(apartment_id, status);

-- 3. 기존 데이터를 'approved' 상태로 업데이트 (이전 데이터는 모두 승인됨으로 처리)
UPDATE public.vacations
SET status = 'approved',
    approved_at = created_at
WHERE status IS NULL OR status = 'pending';

COMMENT ON COLUMN public.vacations.status IS '승인 상태: pending(대기중), approved(승인됨), rejected(거부됨)';
COMMENT ON COLUMN public.vacations.approved_by IS '승인자 ID (직원 또는 관리자)';
COMMENT ON COLUMN public.vacations.approved_at IS '승인 처리 시각';
COMMENT ON COLUMN public.vacations.rejection_reason IS '거부 사유';

-- 4. 검증 쿼리
SELECT 
  status, 
  COUNT(*) as count,
  MIN(vacation_date) as earliest,
  MAX(vacation_date) as latest
FROM public.vacations
GROUP BY status
ORDER BY status;

-- =====================================================
-- 사용 방법:
-- 1. Supabase SQL Editor에서 이 스크립트 실행
-- 2. 검증 쿼리 결과 확인
-- =====================================================
