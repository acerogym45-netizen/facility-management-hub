-- ============================================================
-- 카테고리 관리 RLS 정책 수정
-- Fix Category Management RLS Policy
-- ============================================================
-- 
-- 문제: "new row violates row-level security policy for table document_categories"
-- 원인: document_categories 테이블에 INSERT/UPDATE/DELETE 정책이 없음
-- 해결: 인증된 사용자가 카테고리를 관리할 수 있도록 정책 추가
--
-- ============================================================

-- Step 1: 기존 정책 확인 (선택사항)
-- 현재 어떤 정책이 있는지 확인
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
WHERE tablename = 'document_categories';

-- ============================================================
-- Step 2: 기존 정책 삭제 (있다면)
-- ============================================================

DROP POLICY IF EXISTS "Anyone can view active categories" ON document_categories;
DROP POLICY IF EXISTS "Authenticated users can manage categories" ON document_categories;
DROP POLICY IF EXISTS "Enable read access for all users" ON document_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON document_categories;

-- ============================================================
-- Step 3: 새로운 RLS 정책 생성
-- ============================================================

-- 정책 1: 모든 사용자가 활성 카테고리 조회 가능
CREATE POLICY "Enable read access for all users"
ON document_categories
FOR SELECT
USING (is_active = true);

-- 정책 2: 인증된 사용자가 카테고리 추가 가능
CREATE POLICY "Enable insert for authenticated users"
ON document_categories
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 정책 3: 인증된 사용자가 카테고리 수정 가능
CREATE POLICY "Enable update for authenticated users"
ON document_categories
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 정책 4: 인증된 사용자가 카테고리 삭제 가능
CREATE POLICY "Enable delete for authenticated users"
ON document_categories
FOR DELETE
TO authenticated
USING (true);

-- ============================================================
-- Step 4: RLS 활성화 확인
-- ============================================================

-- RLS가 활성화되어 있는지 확인
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'document_categories';

-- RLS가 비활성화되어 있다면 활성화
ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Step 5: 정책 확인
-- ============================================================

-- 생성된 정책 확인
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'document_categories'
ORDER BY policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 4개의 정책이 표시되어야 합니다:
-- 
-- 1. Enable read access for all users (SELECT)
-- 2. Enable insert for authenticated users (INSERT)
-- 3. Enable update for authenticated users (UPDATE)
-- 4. Enable delete for authenticated users (DELETE)
--
-- ============================================================

-- ============================================================
-- 테스트 쿼리 (선택사항)
-- ============================================================

-- 카테고리 목록 조회 테스트
SELECT id, name, description, icon, color, display_order 
FROM document_categories 
WHERE is_active = true
ORDER BY display_order;

-- 새 카테고리 삽입 테스트 (인증된 상태에서 실행)
-- INSERT INTO document_categories (name, description, icon, color, display_order) 
-- VALUES ('테스트', '테스트 카테고리', 'fa-folder', 'blue', 99);

-- ============================================================
-- 참고: anon (익명) vs authenticated (인증됨)
-- ============================================================
-- 
-- anon: 로그인하지 않은 사용자 (공개 API 키 사용)
-- authenticated: 로그인한 사용자 (인증 토큰 사용)
--
-- 웹 애플리케이션에서 Supabase 클라이언트를 사용할 때는
-- 'authenticated' 역할로 요청이 전송됩니다.
-- 
-- ============================================================

-- ============================================================
-- 문제 해결 체크리스트
-- ============================================================
-- 
-- ✅ RLS가 활성화되어 있는가?
-- ✅ INSERT/UPDATE/DELETE 정책이 존재하는가?
-- ✅ 정책이 'authenticated' 역할에 적용되는가?
-- ✅ WITH CHECK 조건이 너무 제한적이지 않은가?
-- 
-- ============================================================
