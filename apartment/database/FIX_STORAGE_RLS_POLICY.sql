-- ============================================================
-- 서류 업로드 RLS 정책 수정
-- Fix Document Upload Storage RLS Policy
-- ============================================================
-- 
-- 문제: "new row violates row-level security policy for table document_templates"
-- 원인: document_templates 스토리지 버킷의 RLS 정책이 올바르게 설정되지 않음
-- 해결: 인증된 사용자가 파일을 업로드/삭제할 수 있도록 정책 수정
--
-- ============================================================

-- ============================================================
-- 중요: Storage RLS 정책은 SQL이 아닌 Supabase 대시보드에서 설정해야 합니다!
-- ============================================================

/*
  이 파일은 참고용입니다.
  실제로는 Supabase Dashboard > Storage > document-templates > Policies에서 설정하세요.
  
  하지만 SQL로도 가능합니다. 아래 SQL을 사용하세요.
*/

-- ============================================================
-- Step 1: 기존 Storage 정책 확인
-- ============================================================

-- storage.objects 테이블의 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- ============================================================
-- Step 2: 기존 정책 삭제 (document-templates 버킷 관련)
-- ============================================================

-- 주의: bucket_id를 확인해야 합니다
-- document-templates 버킷의 실제 이름 확인
SELECT id, name FROM storage.buckets;

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete" ON storage.objects;
DROP POLICY IF EXISTS "Public read access to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete from document-templates" ON storage.objects;

-- ============================================================
-- Step 3: 새로운 Storage 정책 생성
-- ============================================================

-- 정책 1: 모든 사용자가 document-templates 버킷의 파일 조회 가능
CREATE POLICY "Public read access to document-templates"
ON storage.objects
FOR SELECT
USING (bucket_id = 'document-templates');

-- 정책 2: 인증된 사용자가 document-templates 버킷에 파일 업로드 가능
CREATE POLICY "Authenticated upload to document-templates"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'document-templates');

-- 정책 3: 인증된 사용자가 document-templates 버킷의 파일 업데이트 가능
CREATE POLICY "Authenticated update in document-templates"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'document-templates')
WITH CHECK (bucket_id = 'document-templates');

-- 정책 4: 인증된 사용자가 document-templates 버킷의 파일 삭제 가능
CREATE POLICY "Authenticated delete from document-templates"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'document-templates');

-- ============================================================
-- Step 4: storage.objects 테이블의 RLS 활성화 확인
-- ============================================================

-- RLS가 활성화되어 있는지 확인
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- RLS가 비활성화되어 있다면 활성화 (보통 이미 활성화되어 있음)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Step 5: 정책 확인
-- ============================================================

-- 생성된 정책 확인
SELECT 
  policyname,
  cmd,
  roles,
  SUBSTRING(qual::text, 1, 50) as condition,
  SUBSTRING(with_check::text, 1, 50) as check_condition
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%document-templates%'
ORDER BY policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 4개의 정책이 표시되어야 합니다:
-- 
-- 1. Public read access to document-templates (SELECT)
-- 2. Authenticated upload to document-templates (INSERT)
-- 3. Authenticated update in document-templates (UPDATE)
-- 4. Authenticated delete from document-templates (DELETE)
--
-- ============================================================

-- ============================================================
-- Step 6: documents 테이블 RLS 정책도 확인
-- ============================================================

-- documents 테이블의 정책 확인
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename = 'documents';

-- documents 테이블에 정책이 없다면 생성
DROP POLICY IF EXISTS "Enable read access for all users" ON documents;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON documents;

CREATE POLICY "Enable read access for all users"
ON documents
FOR SELECT
USING (true);

CREATE POLICY "Enable insert for authenticated users"
ON documents
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON documents
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON documents
FOR DELETE
TO authenticated
USING (true);

-- RLS 활성화
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Step 7: 관련된 다른 테이블들도 RLS 정책 설정
-- ============================================================

-- document_versions 테이블
DROP POLICY IF EXISTS "Enable read for all users" ON document_versions;
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_versions;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_versions;

CREATE POLICY "Enable read for all users"
ON document_versions FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated"
ON document_versions FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated"
ON document_versions FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated"
ON document_versions FOR DELETE TO authenticated USING (true);

ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;

-- document_downloads 테이블
DROP POLICY IF EXISTS "Enable read for all" ON document_downloads;
DROP POLICY IF EXISTS "Enable insert for all" ON document_downloads;

CREATE POLICY "Enable read for all"
ON document_downloads FOR SELECT USING (true);

CREATE POLICY "Enable insert for all"
ON document_downloads FOR INSERT WITH CHECK (true);

ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

-- document_favorites 테이블
DROP POLICY IF EXISTS "Enable all for authenticated" ON document_favorites;

CREATE POLICY "Enable all for authenticated"
ON document_favorites FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE document_favorites ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Step 8: 전체 정책 확인
-- ============================================================

-- 모든 document 관련 테이블의 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename LIKE 'document%'
ORDER BY tablename, policyname;

-- ============================================================
-- 테스트 쿼리 (선택사항)
-- ============================================================

-- 1. 버킷 확인
SELECT * FROM storage.buckets WHERE name = 'document-templates';

-- 2. 업로드된 파일 확인 (있다면)
SELECT 
  id,
  name,
  bucket_id,
  owner,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'document-templates'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================
-- 참고: Storage RLS 정책의 작동 방식
-- ============================================================
-- 
-- storage.objects 테이블은 Supabase Storage의 모든 파일 메타데이터를 저장합니다.
-- 
-- bucket_id: 파일이 속한 버킷의 식별자
-- name: 파일의 전체 경로 (예: "folder/file.pdf")
-- owner: 파일을 업로드한 사용자의 ID (authenticated user의 경우)
-- 
-- RLS 정책은 bucket_id를 기준으로 접근을 제어합니다.
-- 
-- ============================================================

-- ============================================================
-- 문제 해결 체크리스트
-- ============================================================
-- 
-- ✅ document-templates 버킷이 존재하는가?
-- ✅ 버킷이 public으로 설정되어 있는가?
-- ✅ storage.objects 테이블에 RLS가 활성화되어 있는가?
-- ✅ INSERT/UPDATE/DELETE 정책이 존재하는가?
-- ✅ 정책이 'authenticated' 역할에 적용되는가?
-- ✅ bucket_id 조건이 정확한가?
-- ✅ documents 테이블에도 RLS 정책이 있는가?
-- 
-- ============================================================
