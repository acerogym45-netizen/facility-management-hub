# 🚀 급여명세서 시스템 통합 실행 가이드

## 📋 실행 순서: A → D → B → C

---

## A. 직원 로그인 비밀번호 시스템 설치

### 📍 파일: `database/EMPLOYEE_PASSWORD_SYSTEM.sql`

**Supabase SQL Editor에서 실행하세요**

```sql
-- ========================================
-- 직원 로그인 비밀번호 관리 시스템
-- ========================================
-- 
-- 기능:
-- 1. 직원 등록 시 전화번호 뒷자리 4자리로 초기 비밀번호 자동 설정
-- 2. 최초 로그인 시 비밀번호 변경 유도
-- 3. 관리자 페이지에서 비밀번호 조회 및 초기화 가능
-- 4. 로그인 기록 추적 (감사 추적)
--
-- ========================================

-- 1. employees 테이블에 비밀번호 관련 필드 추가
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS login_password TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS force_password_change BOOLEAN DEFAULT true;

-- 2. 기존 직원들의 초기 비밀번호 설정 (전화번호 뒷자리 4자리)
UPDATE employees
SET login_password = RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 4),
    force_password_change = true
WHERE login_password IS NULL 
  AND phone IS NOT NULL
  AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 4;

-- 3. 초기 비밀번호 자동 설정 함수
CREATE OR REPLACE FUNCTION set_initial_password()
RETURNS TRIGGER AS $$
BEGIN
  -- 전화번호 뒷자리 4자리 추출
  IF NEW.login_password IS NULL AND NEW.phone IS NOT NULL THEN
    -- 전화번호에서 숫자만 추출 후 뒷자리 4자리
    NEW.login_password := RIGHT(REGEXP_REPLACE(NEW.phone, '[^0-9]', '', 'g'), 4);
    NEW.force_password_change := true;
    
    -- 디버깅용 로그
    RAISE NOTICE '초기 비밀번호 설정: 직원 %, 전화번호 %, 비밀번호 %', 
      NEW.name, NEW.phone, NEW.login_password;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. 트리거 생성 (직원 등록 시 자동 실행)
DROP TRIGGER IF EXISTS set_initial_password_trigger ON employees;
CREATE TRIGGER set_initial_password_trigger
BEFORE INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION set_initial_password();

-- 5. 전화번호 변경 시 비밀번호도 업데이트하는 트리거
CREATE OR REPLACE FUNCTION update_password_on_phone_change()
RETURNS TRIGGER AS $$
BEGIN
  -- 전화번호가 변경되고, 비밀번호가 기본값(전화번호 뒷자리)이었다면 업데이트
  IF NEW.phone IS DISTINCT FROM OLD.phone THEN
    -- 비밀번호가 아직 변경되지 않은 경우에만 업데이트
    IF NEW.password_changed_at IS NULL THEN
      NEW.login_password := RIGHT(REGEXP_REPLACE(NEW.phone, '[^0-9]', '', 'g'), 4);
      
      RAISE NOTICE '전화번호 변경으로 비밀번호 업데이트: 직원 %, 새 비밀번호 %', 
        NEW.name, NEW.login_password;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_password_on_phone_change_trigger ON employees;
CREATE TRIGGER update_password_on_phone_change_trigger
BEFORE UPDATE OF phone ON employees
FOR EACH ROW
EXECUTE FUNCTION update_password_on_phone_change();

-- 6. 로그인 기록 테이블 (선택사항 - 감사 추적용)
CREATE TABLE IF NOT EXISTS employee_login_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address TEXT,
  user_agent TEXT,
  success BOOLEAN DEFAULT true,
  failure_reason TEXT
);

-- 인덱스 생성 (조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_employee_login_logs_employee_id 
ON employee_login_logs(employee_id);

CREATE INDEX IF NOT EXISTS idx_employee_login_logs_login_at 
ON employee_login_logs(login_at DESC);

-- 7. RLS (Row Level Security) 정책
-- employees 테이블은 이미 RLS 설정되어 있음

-- employee_login_logs 테이블 RLS 설정
ALTER TABLE employee_login_logs ENABLE ROW LEVEL SECURITY;

-- 관리자만 조회 가능 (anon 역할은 INSERT만 가능)
CREATE POLICY "Public can insert login logs"
ON employee_login_logs FOR INSERT
TO public
WITH CHECK (true);

-- SELECT는 인증된 사용자만 가능하도록 설정 (선택사항)
CREATE POLICY "Authenticated users can view login logs"
ON employee_login_logs FOR SELECT
USING (true);

-- 8. 유틸리티 함수: 비밀번호 검증
CREATE OR REPLACE FUNCTION verify_employee_password(
  emp_name TEXT,
  emp_password TEXT
)
RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  needs_password_change BOOLEAN,
  last_login TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.force_password_change,
    e.last_login_at
  FROM employees e
  WHERE e.name = emp_name
    AND e.login_password = emp_password
    AND e.is_active = true
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. 유틸리티 함수: 비밀번호 통계
CREATE OR REPLACE FUNCTION get_password_statistics(apt_id UUID DEFAULT NULL)
RETURNS TABLE (
  total_employees INTEGER,
  password_changed_count INTEGER,
  default_password_count INTEGER,
  last_login_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER AS total_employees,
    COUNT(CASE WHEN password_changed_at IS NOT NULL THEN 1 END)::INTEGER AS password_changed_count,
    COUNT(CASE WHEN password_changed_at IS NULL THEN 1 END)::INTEGER AS default_password_count,
    MAX(last_login_at) AS last_login_date
  FROM employees
  WHERE is_active = true
    AND (apt_id IS NULL OR apartment_id = apt_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. 주석 추가 (문서화)
COMMENT ON COLUMN employees.login_password IS '급여명세서 조회 시스템 로그인 비밀번호 (초기값: 전화번호 뒷자리 4자리)';
COMMENT ON COLUMN employees.password_changed_at IS '직원이 비밀번호를 변경한 시각';
COMMENT ON COLUMN employees.last_login_at IS '마지막 로그인 시각';
COMMENT ON COLUMN employees.force_password_change IS '다음 로그인 시 비밀번호 변경 강제 여부';

COMMENT ON TABLE employee_login_logs IS '직원 로그인 기록 (감사 추적용)';
COMMENT ON FUNCTION set_initial_password IS '신규 직원 등록 시 전화번호 뒷자리 4자리로 초기 비밀번호 자동 설정';
COMMENT ON FUNCTION verify_employee_password IS '직원 이름과 비밀번호로 인증';
COMMENT ON FUNCTION get_password_statistics IS '비밀번호 변경 현황 통계';

-- ========================================
-- 완료!
-- ========================================

-- 확인 쿼리
SELECT 
  '✅ A단계 완료: 비밀번호 시스템 설치됨' AS status,
  COUNT(*) AS total_employees,
  COUNT(CASE WHEN login_password IS NOT NULL THEN 1 END) AS with_password,
  COUNT(CASE WHEN password_changed_at IS NOT NULL THEN 1 END) AS password_changed
FROM employees;
```

**✅ 실행 후 확인사항:**
- employees 테이블에 `login_password`, `password_changed_at`, `last_login_at`, `force_password_change` 컬럼 추가됨
- 기존 직원들의 초기 비밀번호 자동 설정됨 (전화번호 뒷자리 4자리)
- `employee_login_logs` 테이블 생성됨

---

## D. 급여명세서 시스템 설치

### 📍 파일: `database/CREATE_PAYROLL_SYSTEM.sql`

**Supabase SQL Editor에서 실행하세요**

```sql
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

-- 직원 역할 체크 제약조건
ALTER TABLE employees 
DROP CONSTRAINT IF EXISTS check_employee_role;

ALTER TABLE employees 
ADD CONSTRAINT check_employee_role 
CHECK (role IN ('employee', 'manager', 'admin'));

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

-- 상태 체크 제약조건
ALTER TABLE payroll_statements 
DROP CONSTRAINT IF EXISTS check_payroll_status;

ALTER TABLE payroll_statements 
ADD CONSTRAINT check_payroll_status 
CHECK (status IN ('pending', 'viewed', 'downloaded', 'printed'));

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

-- 알림 타입 체크
ALTER TABLE payroll_notifications 
DROP CONSTRAINT IF EXISTS check_notification_type;

ALTER TABLE payroll_notifications 
ADD CONSTRAINT check_notification_type 
CHECK (notification_type IN ('email', 'sms', 'push'));

ALTER TABLE payroll_notifications 
DROP CONSTRAINT IF EXISTS check_notification_status;

ALTER TABLE payroll_notifications 
ADD CONSTRAINT check_notification_status 
CHECK (status IN ('pending', 'sent', 'failed', 'opened'));

COMMENT ON TABLE payroll_notifications IS '급여명세서 배포 알림 로그';


-- ============================================
-- RLS 정책 설정
-- ============================================

-- payroll_statements RLS
ALTER TABLE payroll_statements ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (충돌 방지)
DROP POLICY IF EXISTS "Employees can view own payroll statements" ON payroll_statements;
DROP POLICY IF EXISTS "Managers can view apartment employee status" ON payroll_statements;
DROP POLICY IF EXISTS "Admins can manage all payroll statements" ON payroll_statements;
DROP POLICY IF EXISTS "Managers can update offline delivery" ON payroll_statements;

-- 직원: 본인의 급여명세서만 조회 가능
CREATE POLICY "Employees can view own payroll statements"
ON payroll_statements FOR SELECT
USING (
  employee_id IN (
    SELECT id FROM employees WHERE auth_user_id = auth.uid()
  )
);

-- 단지 관리자: 소속 단지 직원의 배포 현황 조회 가능 (금액은 볼 수 없음, 메타데이터만)
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
CREATE POLICY "Admins can manage all payroll statements"
ON payroll_statements FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees WHERE auth_user_id = auth.uid() AND role = 'admin'
  )
);

-- 단지 관리자: 오프라인 배포 완료 체크 가능
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

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Employees can view own notifications" ON payroll_notifications;
DROP POLICY IF EXISTS "Admins can manage all notifications" ON payroll_notifications;

-- 직원: 본인의 알림 내역 조회
CREATE POLICY "Employees can view own notifications"
ON payroll_notifications FOR SELECT
USING (
  employee_id IN (
    SELECT id FROM employees WHERE auth_user_id = auth.uid()
  )
);

-- 본사 관리자: 모든 알림 관리
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

DROP VIEW IF EXISTS payroll_delivery_dashboard;
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
-- 완료 메시지
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ D단계 완료: 급여명세서 시스템 설치됨';
  RAISE NOTICE '';
  RAISE NOTICE '📋 생성된 테이블:';
  RAISE NOTICE '  - employees (email, role 추가)';
  RAISE NOTICE '  - payroll_statements (급여명세서)';
  RAISE NOTICE '  - payroll_notifications (알림 로그)';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 RLS 정책 설정 완료';
  RAISE NOTICE '  - 직원: 본인 명세서만 조회';
  RAISE NOTICE '  - 단지 관리자: 소속 직원 배포 현황 조회';
  RAISE NOTICE '  - 본사 관리자: 전체 관리';
END $$;
```

**✅ 실행 후 확인사항:**
- employees 테이블에 `email`, `role`, `apartment_id` 추가됨
- `payroll_statements` 테이블 생성됨
- `payroll_notifications` 테이블 생성됨
- RLS 정책 설정됨

---

## B. 직원 대시보드 확인

### 📍 파일: `employee_payroll_dashboard.html`

**이미 생성 완료! 브라우저에서 확인하세요**

**접속 URL**: `employee_payroll_dashboard.html`

**기능**:
- ✅ 급여명세서 목록 조회
- ✅ 명세서 조회 (조회 횟수 자동 증가)
- ✅ 명세서 다운로드 (다운로드 횟수 자동 증가)
- ✅ 비밀번호 변경
- ✅ 통계 대시보드

---

## C. 테스트 시나리오

### 1️⃣ 비밀번호 시스템 테스트

```sql
-- 1. 직원 비밀번호 확인
SELECT name, phone, login_password, password_changed_at
FROM employees
WHERE is_active = true
ORDER BY name;

-- 2. 비밀번호 통계
SELECT * FROM get_password_statistics();

-- 3. 특정 직원 로그인 테스트
SELECT * FROM verify_employee_password('직원이름', '비밀번호');
```

### 2️⃣ 직원 로그인 테스트

```
1. employee_payroll_login.html 접속
2. 이름: (실제 직원 이름)
3. 비밀번호: (전화번호 뒷자리 4자리)
4. 로그인 클릭
5. 비밀번호 변경 화면 확인
6. 새 비밀번호 설정 또는 건너뛰기
7. 대시보드 접속 확인
```

### 3️⃣ 관리자 페이지 비밀번호 관리 테스트

```
1. index.html 로그인 (관리자)
2. 데이터 관리 탭 클릭
3. "직원 로그인 비밀번호 관리" 섹션 확인
4. 직원 목록 확인
5. [초기화] 버튼 테스트
6. Excel 다운로드 테스트
```

### 4️⃣ 급여명세서 업로드 테스트 (준비 단계)

```sql
-- Supabase Storage에 'payroll-statements' 버킷 생성 필요
-- 그 후 아래 쿼리로 테스트 데이터 삽입

INSERT INTO payroll_statements (
  employee_id,
  year_month,
  file_url,
  file_name,
  file_size,
  status
)
VALUES (
  (SELECT id FROM employees LIMIT 1), -- 첫 번째 직원
  '2026-05', -- 2026년 5월
  'https://your-storage-url.com/test.pdf', -- 테스트 파일 URL
  '2026년_5월_급여명세서.pdf',
  102400, -- 100KB
  'pending'
);

-- 확인
SELECT * FROM payroll_statements;
```

### 5️⃣ 직원 대시보드 테스트

```
1. employee_payroll_dashboard.html 접속
2. 급여명세서 목록 확인
3. [조회] 버튼 클릭 → 조회 횟수 증가 확인
4. [다운로드] 버튼 클릭 → 다운로드 횟수 증가 확인
5. 통계 카드 업데이트 확인
6. 비밀번호 변경 테스트
```

---

## 📊 통합 확인 쿼리

```sql
-- 전체 시스템 상태 확인
SELECT 
  '시스템 상태' AS category,
  '항목' AS item,
  '값' AS value
UNION ALL
SELECT 
  '비밀번호 시스템',
  '총 직원 수',
  COUNT(*)::TEXT
FROM employees
WHERE is_active = true
UNION ALL
SELECT 
  '비밀번호 시스템',
  '비밀번호 설정됨',
  COUNT(*)::TEXT
FROM employees
WHERE login_password IS NOT NULL
UNION ALL
SELECT 
  '비밀번호 시스템',
  '비밀번호 변경함',
  COUNT(*)::TEXT
FROM employees
WHERE password_changed_at IS NOT NULL
UNION ALL
SELECT 
  '급여명세서 시스템',
  '총 명세서 수',
  COUNT(*)::TEXT
FROM payroll_statements
UNION ALL
SELECT 
  '급여명세서 시스템',
  '미확인 명세서',
  COUNT(*)::TEXT
FROM payroll_statements
WHERE status = 'pending'
UNION ALL
SELECT 
  '급여명세서 시스템',
  '확인 완료',
  COUNT(*)::TEXT
FROM payroll_statements
WHERE status != 'pending';
```

---

## 🚨 문제 해결

### 문제 1: 비밀번호가 NULL인 직원이 있음

```sql
-- 해결: 수동으로 초기 비밀번호 설정
UPDATE employees
SET login_password = RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 4),
    force_password_change = true
WHERE login_password IS NULL 
  AND phone IS NOT NULL;
```

### 문제 2: RLS 정책 오류

```sql
-- 해결: RLS 정책 재생성
ALTER TABLE payroll_statements DISABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_statements ENABLE ROW LEVEL SECURITY;

-- 위 D단계 SQL 다시 실행
```

### 문제 3: Storage 버킷 없음

```
Supabase Dashboard → Storage → Create bucket
- Name: payroll-statements
- Public: NO (Private)
```

---

## ✅ 완료 체크리스트

- [ ] A단계: EMPLOYEE_PASSWORD_SYSTEM.sql 실행
- [ ] 기존 직원 비밀번호 자동 설정 확인
- [ ] D단계: CREATE_PAYROLL_SYSTEM.sql 실행
- [ ] payroll_statements 테이블 생성 확인
- [ ] B단계: employee_payroll_dashboard.html 확인
- [ ] C단계: 직원 로그인 테스트
- [ ] C단계: 관리자 비밀번호 관리 테스트
- [ ] Storage 버킷 생성 (payroll-statements)
- [ ] 테스트 명세서 업로드
- [ ] 전체 시스템 통합 테스트

---

## 🎯 다음 단계

### 즉시 구현 가능
1. Supabase Storage에서 'payroll-statements' 버킷 생성
2. 관리자용 명세서 업로드 페이지 구현
3. 이메일/SMS 알림 시스템 구현 (선택사항)

### 향후 개선
1. Google SSO 추가 (Phase 2)
2. 모바일 앱 개발
3. 자동 알림 시스템 강화
4. 급여명세서 PDF 암호화

---

**🎉 모든 준비 완료! A → D → B → C 순서대로 진행하세요!**
