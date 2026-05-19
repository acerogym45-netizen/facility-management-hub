-- ============================================================
-- 서류 관리 시스템 - RLS 정책 (간단 버전)
-- Document Management RLS Policies (Simple Version)
-- ============================================================
--
-- ⚠️ 주의: 이 스크립트는 테이블 생성 후에 실행하세요!
-- SIMPLE_TABLE_SETUP.sql을 먼저 실행한 후 이 파일을 실행하세요.
--
-- ============================================================

-- ============================================================
-- 1. document_categories 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read access for all users" ON document_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON document_categories;

CREATE POLICY "Enable read access for all users"
ON document_categories FOR SELECT
USING (is_active = true);

CREATE POLICY "Enable insert for authenticated users"
ON document_categories FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON document_categories FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON document_categories FOR DELETE
TO authenticated
USING (true);

ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Storage RLS (document-templates bucket)
-- ============================================================

DROP POLICY IF EXISTS "Public read access to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update in document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete from document-templates" ON storage.objects;

CREATE POLICY "Public read access to document-templates"
ON storage.objects FOR SELECT
USING (bucket_id = 'document-templates');

CREATE POLICY "Authenticated upload to document-templates"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated update in document-templates"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'document-templates')
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated delete from document-templates"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'document-templates');

-- ============================================================
-- 3. documents 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read access for all users" ON documents;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON documents;

CREATE POLICY "Enable read access for all users"
ON documents FOR SELECT
USING (true);

CREATE POLICY "Enable insert for authenticated users"
ON documents FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON documents FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON documents FOR DELETE
TO authenticated
USING (true);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. document_versions 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read for all users" ON document_versions;
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_versions;

CREATE POLICY "Enable read for all users"
ON document_versions FOR SELECT
USING (true);

CREATE POLICY "Enable insert for authenticated"
ON document_versions FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated"
ON document_versions FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated"
ON document_versions FOR DELETE
TO authenticated
USING (true);

ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. document_downloads 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read for all" ON document_downloads;
DROP POLICY IF EXISTS "Enable insert for all" ON document_downloads;

CREATE POLICY "Enable read for all"
ON document_downloads FOR SELECT
USING (true);

CREATE POLICY "Enable insert for all"
ON document_downloads FOR INSERT
WITH CHECK (true);

ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. document_favorites 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable all for authenticated" ON document_favorites;

CREATE POLICY "Enable all for authenticated"
ON document_favorites FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

ALTER TABLE document_favorites ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 7. document_access_logs 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read for all" ON document_access_logs;
DROP POLICY IF EXISTS "Enable insert for all" ON document_access_logs;

CREATE POLICY "Enable read for all"
ON document_access_logs FOR SELECT
USING (true);

CREATE POLICY "Enable insert for all"
ON document_access_logs FOR INSERT
WITH CHECK (true);

ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 8. document_tags 테이블 RLS
-- ============================================================

DROP POLICY IF EXISTS "Enable read for all" ON document_tags;
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_tags;

CREATE POLICY "Enable read for all"
ON document_tags FOR SELECT
USING (true);

CREATE POLICY "Enable insert for authenticated"
ON document_tags FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated"
ON document_tags FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated"
ON document_tags FOR DELETE
TO authenticated
USING (true);

ALTER TABLE document_tags ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 확인 쿼리
-- ============================================================

-- RLS 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename LIKE 'document%' 
   OR (schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%document%')
ORDER BY tablename, policyname;

-- RLS 활성화 확인
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename LIKE 'document%'
ORDER BY tablename;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ 25개 이상의 RLS 정책 생성
-- ✅ 모든 document 테이블에서 rowsecurity = true
-- ✅ Storage bucket에 4개의 정책 생성
--
-- ============================================================
