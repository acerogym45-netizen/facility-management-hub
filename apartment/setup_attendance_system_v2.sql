-- ========================================
-- 출퇴근 차단 시스템 v2.0
-- 2026년 5월 1일부터만 적용
-- ========================================

-- 🔧 수정된 get_all_incomplete_checkouts 함수 (5월 1일 이후만)
CREATE OR REPLACE FUNCTION get_all_incomplete_checkouts(
  apartment_id_param UUID, 
  employee_id_param TEXT DEFAULT NULL
) 
RETURNS TABLE (
  employee_id TEXT,
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
      AND ar.scan_time::DATE < CURRENT_DATE
      AND ar.scan_time >= '2026-05-01'::DATE  -- 🎯 5월 1일 이후만!
  ),
  check_outs AS (
    SELECT 
      ar.employee_id, 
      ar.scan_time::DATE AS check_out_date
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '퇴근'
      AND ar.scan_time >= '2026-05-01'::DATE  -- 🎯 5월 1일 이후만!
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 🔧 수정된 get_incomplete_checkouts 함수 (5월 1일 이후만)
CREATE OR REPLACE FUNCTION get_incomplete_checkouts(
  apartment_id_param UUID, 
  date_param DATE
) 
RETURNS TABLE (
  employee_id TEXT,
  employee_name TEXT, 
  check_in_time TIMESTAMPTZ, 
  hours_since NUMERIC
) AS $$
BEGIN
  -- 🎯 5월 1일 이전이면 빈 결과 반환
  IF date_param < '2026-05-01'::DATE THEN
    RETURN;
  END IF;

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
    SELECT ar.employee_id
    FROM attendance_records ar
    WHERE ar.apartment_id = apartment_id_param
      AND ar.attendance_type = '퇴근'
      AND ar.scan_time::DATE = date_param
  )
  SELECT 
    ci.employee_id, 
    ci.employee_name, 
    ci.check_in_time,
    EXTRACT(EPOCH FROM (NOW() - ci.check_in_time))/3600 AS hours_since
  FROM check_ins ci 
  LEFT JOIN check_outs co ON ci.employee_id = co.employee_id
  WHERE co.employee_id IS NULL
  ORDER BY ci.check_in_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 권한 설정
GRANT EXECUTE ON FUNCTION get_incomplete_checkouts(UUID, DATE) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_all_incomplete_checkouts(UUID, TEXT) TO anon, authenticated, service_role;

-- 완료 메시지
DO $$ 
BEGIN 
  RAISE NOTICE '✅ 차단 시스템 v2.0 업데이트 완료!';
  RAISE NOTICE '   - 2026년 5월 1일부터만 차단 적용';
  RAISE NOTICE '   - 4월 30일 이전 기록은 무시';
END $$;
