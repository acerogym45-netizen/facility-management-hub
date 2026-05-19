-- ============================================
-- 급여명세서 자동 배포 시스템
-- ============================================
-- Phase 1: 직원 계정 및 인증 시스템
-- Phase 2: 급여명세서 관리
-- Phase 3: 자동 알림 시스템
-- ============================================

-- ============================================
-- Phase 1: 직원 계정 시스템
-- ============================================

-- 1. employees 테이블에 로그인 정보 추가
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS email TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'employee', -- employee, manager, admin
ADD COLUMN IF NOT EXISTS apartment_id UUID, -- 소속 단지
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;

-- 이메일 인덱스
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_auth_user ON employees(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_employees_apartment ON employees(apartment_id);

-- 직원 역할 체크 제약조건 (이미 존재하면 스킵)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_employee_role'
  ) THEN
    ALTER TABLE employees 
    ADD CONSTRAINT check_employee_role 
    CHECK (role IN ('employee', 'manager', 'admin'));
  END IF;
END $$;

COMMENT ON COLUMN employees.email IS '직원 로그인 이메일';
COMMENT ON COLUMN employees.auth_user_id IS 'Supabase Auth 사용자 ID';
COMMENT ON COLUMN employees.role IS '직원 역할: employee(일반), manager(단지관리자), admin(본사)';
COMMENT ON COLUMN employees.apartment_id IS '소속 단지 ID';


-- ============================================
-- Phase 2: 급여명세서 테이블
-- ============================================

-- 급여명세서 메타데이터 테이블
CREATE TABLE IF NOT EXISTS payroll_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  year_month TEXT NOT NULL, -- '2026-05' 형식
  file_url TEXT NOT NULL, -- Supabase Storage URL
  file_name TEXT NOT NULL, -- 원본 파일명
  file_size INTEGER, -- 파일 크기 (bytes)
  pdf_password TEXT, -- PDF 암호 (선택사항)
  
  -- 상태 관리
  status TEXT DEFAULT 'pending', -- pending, viewed, downloaded, printed
  uploaded_by UUID REFERENCES employees(id), -- 업로드한 본사 직원
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 조회 기록
  first_viewed_at TIMESTAMP WITH TIME ZONE,
  last_viewed_at TIMESTAMP WITH TIME ZONE,
  view_count INTEGER DEFAULT 0,
  download_count INTEGER DEFAULT 0,
  
  -- 알림 기록
  email_sent_at TIMESTAMP WITH TIME ZONE,
  email_opened_at TIMESTAMP WITH TIME ZONE,
  sms_sent_at TIMESTAMP WITH TIME ZONE,
  
  -- 오프라인 배포 기록 (단지 관리자가 직접 전달한 경우)
  offline_delivered BOOLEAN DEFAULT false,
  offline_delivered_by UUID REFERENCES employees(id),
  offline_delivered_at TIMESTAMP WITH TIME ZONE,
  offline_delivery_note TEXT,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_payroll_employee ON payroll_statements(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_year_month ON payroll_statements(year_month);
CREATE INDEX IF NOT EXISTS idx_payroll_status ON payroll_statements(status);
CREATE INDEX IF NOT EXISTS idx_payroll_uploaded_by ON payroll_statements(uploaded_by);

-- 유니크 제약: 한 직원의 같은 년월에 중복 명세서 방지
CREATE UNIQUE INDEX IF NOT EXISTS idx_payroll_employee_month 
ON payroll_statements(employee_id, year_month);

-- 상태 체크 제약조건 (이미 존재하면 스킵)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_payroll_status'
  ) THEN
    ALTER TABLE payroll_statements 
    ADD CONSTRAINT check_payroll_status 
    CHECK (status IN ('pending', 'viewed', 'downloaded', 'printed'));
  END IF;
END $$;

-- 테이블 코멘트
COMMENT ON TABLE payroll_statements IS '급여명세서 메타데이터 및 배포 현황';
COMMENT ON COLUMN payroll_statements.year_month IS '급여 년월 (YYYY-MM)';
COMMENT ON COLUMN payroll_statements.status IS '상태: pending(미확인), viewed(조회), downloaded(다운로드), printed(출력)';
COMMENT ON COLUMN payroll_statements.offline_delivered IS '오프라인 전달 여부 (단지 관리자가 직접 전달)';


-- ============================================
-- Phase 3: 배포 알림 로그 테이블
-- ============================================

CREATE TABLE IF NOT EXISTS payroll_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_statement_id UUID NOT NULL REFERENCES payroll_statements(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  
  -- 알림 타입
  notification_type TEXT NOT NULL, -- email, sms, push
  
  -- 알림 내용
  recipient TEXT NOT NULL, -- 이메일 주소 또는 전화번호
  subject TEXT,
  message TEXT,
  
  -- 발송 상태
  status TEXT DEFAULT 'pending', -- pending, sent, failed, opened
  sent_at TIMESTAMP WITH TIME ZONE,
  opened_at TIMESTAMP WITH TIME ZONE,
  failed_reason TEXT,
  
  -- 재시도 정보
  retry_count INTEGER DEFAULT 0,
  max_retry INTEGER DEFAULT 3,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_notification_payroll ON payroll_notifications(payroll_statement_id);
CREATE INDEX IF NOT EXISTS idx_notification_employee ON payroll_notifications(employee_id);
CREATE INDEX IF NOT EXISTS idx_notification_status ON payroll_notifications(status);
CREATE INDEX IF NOT EXISTS idx_notification_type ON payroll_notifications(notification_type);

-- 알림 타입 체크 (이미 존재하면 스킵)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_notification_type'
  ) THEN
    ALTER TABLE payroll_notifications 
    ADD CONSTRAINT check_notification_type 
    CHECK (notification_type IN ('email', 'sms', 'push'));
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_notification_status'
  ) THEN
    ALTER TABLE payroll_notifications 
    ADD CONSTRAINT check_notification_status 
    CHECK (status IN ('pending', 'sent', 'failed', 'opened'));
  END IF;
END $$;

COMMENT ON TABLE payroll_notifications IS '급여명세서 배포 알림 로그';


-- ============================================
-- RLS 정책 설정
-- ============================================

-- payroll_statements RLS
ALTER TABLE payroll_statements ENABLE ROW LEVEL SECURITY;

-- 직원: 본인의 급여명세서만 조회 가능
DROP POLICY IF EXISTS "Employees can view own payroll statements" ON payroll_statements;
CREATE POLICY "Employees can view own payroll statements"
ON payroll_statements FOR SELECT
USING (
  employee_id IN (
    SELECT id FROM employees WHERE auth_user_id = auth.uid()
  )
);

-- 단지 관리자: 소속 단지 직원의 배포 현황 조회 가능 (금액은 볼 수 없음, 메타데이터만)
DROP POLICY IF EXISTS "Managers can view apartment employee status" ON payroll_statements;
CREATE POLICY "Managers can view apartment employee status"
ON payroll_statements FOR SELECT
USING (
  employee_id IN (
    SELECT e.id FROM employees e
    WHERE e.apartment_id IN (
      SELECT apartment_id FROM employees WHERE auth_user_id = auth.uid() AND role = 'manager'
    )
  )
);

-- 본사 관리자: 모든 명세서 조회 및 업로드 가능
DROP POLICY IF EXISTS "Admins can manage all payroll statements" ON payroll_statements;
CREATE POLICY "Admins can manage all payroll statements"
ON payroll_statements FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees WHERE auth_user_id = auth.uid() AND role = 'admin'
  )
);

-- 단지 관리자: 오프라인 배포 완료 체크 가능
DROP POLICY IF EXISTS "Managers can update offline delivery" ON payroll_statements;
CREATE POLICY "Managers can update offline delivery"
ON payroll_statements FOR UPDATE
USING (
  employee_id IN (
    SELECT e.id FROM employees e
    WHERE e.apartment_id IN (
      SELECT apartment_id FROM employees WHERE auth_user_id = auth.uid() AND role = 'manager'
    )
  )
)
WITH CHECK (
  -- 오프라인 배포 필드만 수정 가능
  offline_delivered IS NOT NULL
);


-- payroll_notifications RLS
ALTER TABLE payroll_notifications ENABLE ROW LEVEL SECURITY;

-- 직원: 본인의 알림 내역 조회
DROP POLICY IF EXISTS "Employees can view own notifications" ON payroll_notifications;
CREATE POLICY "Employees can view own notifications"
ON payroll_notifications FOR SELECT
USING (
  employee_id IN (
    SELECT id FROM employees WHERE auth_user_id = auth.uid()
  )
);

-- 본사 관리자: 모든 알림 관리
DROP POLICY IF EXISTS "Admins can manage all notifications" ON payroll_notifications;
CREATE POLICY "Admins can manage all notifications"
ON payroll_notifications FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees WHERE auth_user_id = auth.uid() AND role = 'admin'
  )
);


-- ============================================
-- 함수: 급여명세서 조회 시 자동 업데이트
-- ============================================

CREATE OR REPLACE FUNCTION update_payroll_view_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- 최초 조회 시간 기록
  IF OLD.first_viewed_at IS NULL THEN
    NEW.first_viewed_at = NOW();
  END IF;
  
  -- 마지막 조회 시간 업데이트
  NEW.last_viewed_at = NOW();
  
  -- 조회 횟수 증가
  NEW.view_count = OLD.view_count + 1;
  
  -- 상태가 pending이면 viewed로 변경
  IF OLD.status = 'pending' THEN
    NEW.status = 'viewed';
  END IF;
  
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성 (조회 시 자동 실행)
DROP TRIGGER IF EXISTS trigger_update_payroll_view_stats ON payroll_statements;
CREATE TRIGGER trigger_update_payroll_view_stats
BEFORE UPDATE OF last_viewed_at ON payroll_statements
FOR EACH ROW
EXECUTE FUNCTION update_payroll_view_stats();


-- ============================================
-- 함수: 미수령자 목록 조회
-- ============================================

CREATE OR REPLACE FUNCTION get_undelivered_payroll(target_year_month TEXT)
RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  employee_email TEXT,
  apartment_name TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE,
  days_pending INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.email,
    a.name AS apartment_name,
    ps.uploaded_at,
    EXTRACT(DAY FROM NOW() - ps.uploaded_at)::INTEGER AS days_pending
  FROM payroll_statements ps
  JOIN employees e ON ps.employee_id = e.id
  LEFT JOIN apartments a ON e.apartment_id = a.id
  WHERE ps.year_month = target_year_month
    AND ps.status = 'pending'
    AND ps.offline_delivered = false
  ORDER BY ps.uploaded_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================
-- 뷰: 배포 현황 대시보드
-- ============================================

CREATE OR REPLACE VIEW payroll_delivery_dashboard AS
SELECT 
  ps.year_month,
  COUNT(*) AS total_statements,
  COUNT(*) FILTER (WHERE ps.status = 'pending') AS pending_count,
  COUNT(*) FILTER (WHERE ps.status = 'viewed') AS viewed_count,
  COUNT(*) FILTER (WHERE ps.status = 'downloaded') AS downloaded_count,
  COUNT(*) FILTER (WHERE ps.offline_delivered = true) AS offline_delivered_count,
  ROUND(
    COUNT(*) FILTER (WHERE ps.status != 'pending' OR ps.offline_delivered = true)::NUMERIC / 
    COUNT(*)::NUMERIC * 100, 
    2
  ) AS delivery_rate
FROM payroll_statements ps
GROUP BY ps.year_month
ORDER BY ps.year_month DESC;

COMMENT ON VIEW payroll_delivery_dashboard IS '급여명세서 배포 현황 대시보드';


-- ============================================
-- 샘플 데이터 (테스트용)
-- ============================================

-- 본사 관리자 계정 (기존 직원 업데이트)
-- 실제 사용 시 실제 이메일로 변경 필요
-- UPDATE employees 
-- SET email = 'admin@masterplan.com',
--     role = 'admin'
-- WHERE employee_number = 'MASTER001';

-- 단지 관리자 샘플 (필요 시)
-- UPDATE employees 
-- SET email = 'manager1@masterplan.com',
--     role = 'manager',
--     apartment_id = (SELECT id FROM apartments LIMIT 1)
-- WHERE employee_number = 'MGR001';


-- ============================================
-- 완료 메시지
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ 급여명세서 자동 배포 시스템 설치 완료';
  RAISE NOTICE '';
  RAISE NOTICE '📋 생성된 테이블:';
  RAISE NOTICE '  - employees (로그인 정보 추가)';
  RAISE NOTICE '  - payroll_statements (급여명세서)';
  RAISE NOTICE '  - payroll_notifications (알림 로그)';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 RLS 정책 설정 완료';
  RAISE NOTICE '  - 직원: 본인 명세서만 조회';
  RAISE NOTICE '  - 단지 관리자: 소속 직원 배포 현황 조회';
  RAISE NOTICE '  - 본사 관리자: 전체 관리';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 다음 단계:';
  RAISE NOTICE '  1. employees 테이블에 이메일 주소 추가';
  RAISE NOTICE '  2. Supabase Auth에서 직원 계정 생성';
  RAISE NOTICE '  3. 급여명세서 업로드 페이지 구축';
  RAISE NOTICE '  4. 직원 로그인 페이지 구축';
END $$;
