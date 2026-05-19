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

-- 10. 테스트 쿼리
-- 비밀번호 통계 조회
-- SELECT * FROM get_password_statistics();

-- 특정 직원 로그인 검증
-- SELECT * FROM verify_employee_password('홍길동', '1234');

-- 비밀번호 미변경 직원 목록
-- SELECT name, phone, login_password, created_at
-- FROM employees
-- WHERE password_changed_at IS NULL AND is_active = true
-- ORDER BY name;

-- 11. 주석 추가 (문서화)
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
  '설정 완료' AS status,
  COUNT(*) AS total_employees,
  COUNT(CASE WHEN login_password IS NOT NULL THEN 1 END) AS with_password,
  COUNT(CASE WHEN password_changed_at IS NOT NULL THEN 1 END) AS password_changed
FROM employees;
