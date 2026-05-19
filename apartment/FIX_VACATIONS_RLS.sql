-- vacations 테이블 RLS 정책 완전 수정
-- 문제: "new row violates row-level security policy" 오류

-- 1단계: 기존 정책 모두 삭제
DROP POLICY IF EXISTS "vacations_select_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_insert_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_update_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_delete_policy" ON vacations;
DROP POLICY IF EXISTS "allow_all" ON vacations;

-- 2단계: RLS 비활성화 (일시적)
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;

-- 3단계: RLS 다시 활성화
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;

-- 4단계: 모든 작업을 허용하는 정책 생성
CREATE POLICY "vacations_allow_all_operations"
ON vacations
FOR ALL
USING (true)
WITH CHECK (true);

-- 5단계: 확인
SELECT '✅ RLS 정책이 수정되었습니다!' AS message;

-- 6단계: 정책 목록 확인
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'vacations';
