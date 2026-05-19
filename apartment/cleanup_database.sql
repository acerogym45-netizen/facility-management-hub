-- 1. 오래된 청소 사진 삭제 (3개월 이상 된 데이터)
DELETE FROM cleaning_tasks 
WHERE created_at < NOW() - INTERVAL '3 months';

-- 2. 오래된 출퇴근 기록 삭제 (6개월 이상)
DELETE FROM attendance_records 
WHERE scan_time < NOW() - INTERVAL '6 months';

-- 3. 스토리지 정리 (사용하지 않는 파일)
-- Supabase Storage → cleaning-photos 버킷에서 수동 삭제 필요

-- 4. 테이블 용량 확인 쿼리
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
