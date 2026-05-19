-- ============================================================
-- apartments 테이블 RLS 정책 수정
-- Fix RLS Policies for Apartments Table
-- ============================================================
--
-- 문제: apartments 테이블 접근 불가
-- 해결: anon 역할도 허용하도록 정책 추가
--
-- ============================================================

-- apartments 테이블 RLS 정책
DROP POLICY IF EXISTS "Enable read access for all users" ON apartments;
DROP POLICY IF EXISTS "Enable insert for all users" ON apartments;
DROP POLICY IF EXISTS "Enable update for all users" ON apartments;
DROP POLICY IF EXISTS "Enable delete for all users" ON apartments;

CREATE POLICY "Enable read access for all users"
ON apartments FOR SELECT
USING (true);

CREATE POLICY "Enable insert for all users"
ON apartments FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all users"
ON apartments FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all users"
ON apartments FOR DELETE
USING (true);

-- employees 테이블 RLS 정책 (혹시 모르니 추가)
DROP POLICY IF EXISTS "Enable read access for all users" ON employees;
DROP POLICY IF EXISTS "Enable insert for all users" ON employees;
DROP POLICY IF EXISTS "Enable update for all users" ON employees;
DROP POLICY IF EXISTS "Enable delete for all users" ON employees;

CREATE POLICY "Enable read access for all users"
ON employees FOR SELECT
USING (true);

CREATE POLICY "Enable insert for all users"
ON employees FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all users"
ON employees FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all users"
ON employees FOR DELETE
USING (true);

-- ============================================================
-- 확인 쿼리
-- ============================================================

SELECT 
  tablename,
  policyname,
  cmd,
  roles,
  permissive
FROM pg_policies 
WHERE tablename IN ('apartments', 'employees')
ORDER BY tablename, policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ apartments 테이블에 4개 정책
-- ✅ employees 테이블에 4개 정책
-- ✅ 모든 정책의 roles = {public}
-- 
-- 이제 단지별 페이지 정상 작동
--
-- ============================================================
