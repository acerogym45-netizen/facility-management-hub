-- Supabase Storage 버킷 및 정책 생성
-- 브랜드 로고 및 자산 업로드를 위한 Storage 설정

-- 1. Storage 버킷 생성 (public 접근 가능)
INSERT INTO storage.buckets (id, name, public)
VALUES ('brand-assets', 'brand-assets', true)
ON CONFLICT (id) DO UPDATE 
SET public = true;

-- 2. Storage RLS 정책 - 누구나 읽기 가능
CREATE POLICY "Public Access for brand-assets"
ON storage.objects FOR SELECT
TO anon, public
USING (bucket_id = 'brand-assets');

-- 3. Storage RLS 정책 - 익명 사용자도 업로드 가능 (관리자 UI에서 사용)
CREATE POLICY "Public Upload for brand-assets"
ON storage.objects FOR INSERT
TO anon, public
WITH CHECK (bucket_id = 'brand-assets');

-- 4. Storage RLS 정책 - 파일 삭제 (authenticated 사용자만)
CREATE POLICY "Authenticated Delete for brand-assets"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'brand-assets');

-- 5. Storage RLS 정책 - 파일 수정 (authenticated 사용자만)
CREATE POLICY "Authenticated Update for brand-assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'brand-assets')
WITH CHECK (bucket_id = 'brand-assets');

-- 확인 쿼리
-- SELECT * FROM storage.buckets WHERE id = 'brand-assets';
-- SELECT * FROM storage.objects WHERE bucket_id = 'brand-assets';
