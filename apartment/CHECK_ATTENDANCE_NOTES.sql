-- 특이사항 데이터 확인 쿼리
-- Supabase SQL Editor에서 실행하세요

-- 1. 최근 특이사항 10건 조회
SELECT 
  id,
  apartment_id,
  employee_name,
  note_date,
  note_time,
  note_type,
  reason,
  created_at
FROM public.attendance_notes
ORDER BY created_at DESC
LIMIT 10;

-- 2. 오늘 날짜의 특이사항 조회
SELECT 
  id,
  apartment_id,
  employee_name,
  note_date,
  note_time,
  note_type,
  reason,
  created_at
FROM public.attendance_notes
WHERE note_date = CURRENT_DATE
ORDER BY created_at DESC;

-- 3. 특이사항 유형별 통계
SELECT 
  note_type,
  COUNT(*) as count
FROM public.attendance_notes
GROUP BY note_type
ORDER BY count DESC;

-- 4. 테스트1 직원의 특이사항 조회
SELECT 
  id,
  note_date,
  note_time,
  note_type,
  reason,
  created_at
FROM public.attendance_notes
WHERE employee_name = '테스트1'
ORDER BY created_at DESC
LIMIT 10;

-- 5. 특정 날짜의 출근 기록과 특이사항 비교
SELECT 
  ar.id as record_id,
  ar.scan_time,
  ar.employee_name,
  ar.attendance_type,
  an.id as note_id,
  an.note_type,
  an.reason
FROM public.attendance_records ar
LEFT JOIN public.attendance_notes an 
  ON ar.employee_name = an.employee_name 
  AND DATE(ar.scan_time AT TIME ZONE 'Asia/Seoul') = an.note_date
WHERE DATE(ar.scan_time AT TIME ZONE 'Asia/Seoul') = '2026-05-08'
ORDER BY ar.scan_time DESC
LIMIT 20;
