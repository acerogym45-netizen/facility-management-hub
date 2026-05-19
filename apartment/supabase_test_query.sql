-- 1️⃣ 먼저 박인수 센터장의 정보 확인
SELECT id, name, apartment_id, status
FROM employees
WHERE name LIKE '%박인수%';

-- 2️⃣ 내포이지더원 아파트 정보 확인
SELECT id, name
FROM apartments
WHERE name LIKE '%내포%';

-- 3️⃣ 박인수 센터장의 모든 출퇴근 기록 확인 (최근 7일)
SELECT 
  employee_name,
  attendance_type,
  scan_time::DATE as date,
  scan_time,
  manual_entry
FROM attendance_records
WHERE employee_name LIKE '%박인수%'
  AND scan_time >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY scan_time DESC;

-- 4️⃣ 미완료 퇴근 기록 조회 (get_all_incomplete_checkouts 함수 테스트)
-- 이 쿼리는 박인수 센터장의 employee_id와 apartment_id를 알아야 실행 가능
-- 위 1️⃣, 2️⃣ 쿼리 결과에서 ID를 확인한 후 아래 주석을 해제하고 실행:

-- SELECT * FROM get_all_incomplete_checkouts(
--   '아파트_ID를_여기에_입력'::UUID,
--   '직원_ID를_여기에_입력'::UUID
-- );

-- 5️⃣ validate_check_in 함수 테스트
-- 위 쿼리 결과에서 ID를 확인한 후 실행:

-- SELECT validate_check_in(
--   '아파트_ID를_여기에_입력'::UUID,
--   '직원_ID를_여기에_입력'::UUID
-- );
