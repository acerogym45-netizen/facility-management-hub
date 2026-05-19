-- =====================================================
-- KINDWON 출퇴근 차단 시스템 DB 설정
-- =====================================================

-- 1️⃣ 편집 불가 로그 테이블 생성
CREATE TABLE IF NOT EXISTS attendance_edit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL,
  record_id UUID NOT NULL,
  editor_name TEXT NOT NULL,
  editor_role TEXT NOT NULL,
  
  field_name TEXT NOT NULL,
  old_value TEXT NOT NULL,
  new_value TEXT NOT NULL,
  
  reason TEXT,
  edited_at TIMESTAMPTZ DEFAULT NOW(),
  
  is_locked BOOLEAN DEFAULT TRUE,
  
  CONSTRAINT fk_apartment FOREIGN KEY (apartment_id) 
    REFERENCES apartments(id) ON DELETE CASCADE,
  CONSTRAINT fk_record FOREIGN KEY (record_id)
    REFERENCES attendance_records(id) ON DELETE CASCADE
);

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_edit_logs_record ON attendance_edit_logs(record_id);
CREATE INDEX IF NOT EXISTS idx_edit_logs_apartment ON attendance_edit_logs(apartment_id);
CREATE INDEX IF NOT EXISTS idx_edit_logs_edited_at ON attendance_edit_logs(edited_at DESC);

-- RLS 정책 설정
ALTER TABLE attendance_edit_logs ENABLE ROW LEVEL SECURITY;

-- 읽기: 모든 사용자 가능
DROP POLICY IF EXISTS "로그 읽기 허용" ON attendance_edit_logs;
CREATE POLICY "로그 읽기 허용"
ON attendance_edit_logs FOR SELECT
USING (true);

-- 생성: 애플리케이션에서만 가능
DROP POLICY IF EXISTS "로그 생성 제한" ON attendance_edit_logs;
CREATE POLICY "로그 생성 제한"
ON attendance_edit_logs FOR INSERT
WITH CHECK (is_locked = true);

-- 수정/삭제: 완전 차단
DROP POLICY IF EXISTS "로그 수정 차단" ON attendance_edit_logs;
CREATE POLICY "로그 수정 차단"
ON attendance_edit_logs FOR UPDATE
USING (false);

DROP POLICY IF EXISTS "로그 삭제 차단" ON attendance_edit_logs;
CREATE POLICY "로그 삭제 차단"
ON attendance_edit_logs FOR DELETE
USING (false);

-- 2️⃣ 미완료 출근 조회 함수
CREATE OR REPLACE FUNCTION get_incomplete_checkouts(
  apartment_id_param UUID,
  date_param DATE
) RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  check_in_time TIMESTAMPTZ,
  hours_since NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH check_ins AS (
    SELECT 
      ar.employee_id,
      ar.employee_name,
      ar.scan_time AS check_in_time
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '출근'
      AND ar.scan_time::DATE = date_param
  ),
  check_outs AS (
    SELECT 
      ar.employee_id
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '퇴근'
      AND ar.scan_time::DATE = date_param
  )
  SELECT 
    ci.employee_id,
    ci.employee_name,
    ci.check_in_time,
    EXTRACT(EPOCH FROM (NOW() - ci.check_in_time)) / 3600 AS hours_since
  FROM check_ins ci
  LEFT JOIN check_outs co ON ci.employee_id = co.employee_id
  WHERE co.employee_id IS NULL
  ORDER BY ci.check_in_time;
END;
$$ LANGUAGE plpgsql;

-- 3️⃣ 전체 미완료 출근 조회 (모든 과거 날짜)
CREATE OR REPLACE FUNCTION get_all_incomplete_checkouts(
  apartment_id_param UUID,
  employee_id_param UUID DEFAULT NULL
) RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  check_in_date DATE,
  check_in_time TIMESTAMPTZ,
  days_ago INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH all_check_ins AS (
    SELECT 
      ar.employee_id,
      ar.employee_name,
      ar.scan_time::DATE AS check_in_date,
      ar.scan_time AS check_in_time
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '출근'
      AND (employee_id_param IS NULL OR ar.employee_id = employee_id_param)
      AND ar.scan_time::DATE < CURRENT_DATE -- 오늘은 제외
  ),
  check_outs AS (
    SELECT 
      ar.employee_id,
      ar.scan_time::DATE AS check_out_date
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '퇴근'
  )
  SELECT 
    ci.employee_id,
    ci.employee_name,
    ci.check_in_date,
    ci.check_in_time,
    (CURRENT_DATE - ci.check_in_date)::INTEGER AS days_ago
  FROM all_check_ins ci
  LEFT JOIN check_outs co 
    ON ci.employee_id = co.employee_id 
    AND ci.check_in_date = co.check_out_date
  WHERE co.employee_id IS NULL
  ORDER BY ci.check_in_date DESC, ci.employee_name;
END;
$$ LANGUAGE plpgsql;

-- 4️⃣ 출근 차단 검증 함수
CREATE OR REPLACE FUNCTION validate_check_in(
  apartment_id_param UUID,
  employee_id_param UUID
) RETURNS JSON AS $$
DECLARE
  incomplete_count INTEGER;
  incomplete_records JSON;
  result JSON;
BEGIN
  -- 미완료 출근 개수 확인
  SELECT COUNT(*)::INTEGER INTO incomplete_count
  FROM get_all_incomplete_checkouts(apartment_id_param, employee_id_param);
  
  -- 미완료 기록 상세 정보
  SELECT json_agg(
    json_build_object(
      'date', check_in_date,
      'time', check_in_time,
      'days_ago', days_ago
    )
  ) INTO incomplete_records
  FROM get_all_incomplete_checkouts(apartment_id_param, employee_id_param);
  
  -- 결과 반환
  IF incomplete_count > 0 THEN
    result := json_build_object(
      'allowed', false,
      'blocked', true,
      'reason', 'incomplete_checkout',
      'incomplete_count', incomplete_count,
      'incomplete_records', COALESCE(incomplete_records, '[]'::json)
    );
  ELSE
    result := json_build_object(
      'allowed', true,
      'blocked', false
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 5️⃣ attendance_records에 manual_entry 컬럼 추가 (이미 있으면 무시)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance_records' 
    AND column_name = 'manual_entry'
  ) THEN
    ALTER TABLE attendance_records 
    ADD COLUMN manual_entry BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_attendance_employee_type_date 
ON attendance_records(employee_id, attendance_type, (scan_time::DATE));

CREATE INDEX IF NOT EXISTS idx_attendance_apartment_date 
ON attendance_records(apartment_id, (scan_time::DATE));

-- 완료 메시지
DO $$ 
BEGIN
  RAISE NOTICE '✅ 출퇴근 차단 시스템 DB 설정 완료!';
  RAISE NOTICE '   - attendance_edit_logs 테이블 생성';
  RAISE NOTICE '   - get_incomplete_checkouts() 함수 생성';
  RAISE NOTICE '   - get_all_incomplete_checkouts() 함수 생성';
  RAISE NOTICE '   - validate_check_in() 함수 생성';
  RAISE NOTICE '   - manual_entry 컬럼 추가';
  RAISE NOTICE '   - 인덱스 및 RLS 정책 설정';
END $$;
