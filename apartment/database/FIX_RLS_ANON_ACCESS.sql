-- ============================================================
-- RLS 정책 수정 - anon 역할도 허용
-- Fix RLS Policies to Allow Anonymous Access
-- ============================================================
--
-- 문제: authenticated 역할만 INSERT/UPDATE/DELETE 가능
-- 해결: anon 역할도 허용하도록 수정
--
-- ============================================================

-- 1. document_categories 정책 수정
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON document_categories;

CREATE POLICY "Enable insert for all users"
ON document_categories FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all users"
ON document_categories FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all users"
ON document_categories FOR DELETE
USING (true);

-- 2. Storage 정책 수정
DROP POLICY IF EXISTS "Authenticated upload to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update in document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete from document-templates" ON storage.objects;

CREATE POLICY "Allow upload to document-templates"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Allow update in document-templates"
ON storage.objects FOR UPDATE
USING (bucket_id = 'document-templates')
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Allow delete from document-templates"
ON storage.objects FOR DELETE
USING (bucket_id = 'document-templates');

-- 3. documents 정책 수정
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON documents;

CREATE POLICY "Enable insert for all users"
ON documents FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all users"
ON documents FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all users"
ON documents FOR DELETE
USING (true);

-- 4. document_versions 정책 수정
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_versions;

CREATE POLICY "Enable insert for all"
ON document_versions FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all"
ON document_versions FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all"
ON document_versions FOR DELETE
USING (true);

-- 5. document_favorites 정책 수정
DROP POLICY IF EXISTS "Enable all for authenticated" ON document_favorites;

CREATE POLICY "Enable all for users"
ON document_favorites FOR ALL
USING (true)
WITH CHECK (true);

-- 6. document_tags 정책 수정
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_tags;

CREATE POLICY "Enable insert for all"
ON document_tags FOR INSERT
WITH CHECK (true);

CREATE POLICY "Enable update for all"
ON document_tags FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for all"
ON document_tags FOR DELETE
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
WHERE tablename IN ('document_categories', 'documents', 'document_versions', 'document_favorites', 'document_tags')
   OR (schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%document%')
ORDER BY tablename, policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ 모든 정책의 roles = {public} (모든 사용자)
-- ✅ permissive = true
-- 
-- 이제 anon 키로 접근해도 INSERT/UPDATE/DELETE 가능
--
-- ============================================================
