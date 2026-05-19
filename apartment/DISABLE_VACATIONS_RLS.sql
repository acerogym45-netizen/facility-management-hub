-- vacations 테이블 RLS 완전 비활성화
-- RLS 정책으로 인한 모든 문제 해결

-- 방법 1: RLS 완전 비활성화 (가장 간단)
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;

SELECT '✅ vacations 테이블의 RLS가 비활성화되었습니다!' AS message;

-- 확인
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename = 'vacations';
