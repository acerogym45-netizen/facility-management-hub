-- ============================================================
-- 📋 올바른 설치 순서
-- ============================================================
-- 
-- ❌ 현재 문제: documents 테이블이 존재하지 않음
-- ✅ 해결: 테이블 생성 → RLS 정책 설정 순서로 진행
--
-- ============================================================

-- ============================================================
-- STEP 1: 데이터베이스 테이블 생성 (먼저 실행!)
-- ============================================================

BEGIN;

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. document_categories 테이블
CREATE TABLE IF NOT EXISTS document_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50) DEFAULT 'fa-folder',
  color VARCHAR(20) DEFAULT 'gray',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. documents 테이블 (document_templates 대신 간단한 이름 사용)
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES document_categories(id) ON DELETE SET NULL,
  file_url TEXT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size BIGINT,
  file_type VARCHAR(50),
  uploaded_by VARCHAR(255),
  apartment_id UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  download_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 3. document_versions 테이블
CREATE TABLE IF NOT EXISTS document_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  file_url TEXT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  uploaded_by VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  notes TEXT
);

-- 4. document_downloads 테이블
CREATE TABLE IF NOT EXISTS document_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  downloaded_by VARCHAR(255),
  downloaded_at TIMESTAMP DEFAULT NOW(),
  ip_address INET
);

-- 5. document_favorites 테이블
CREATE TABLE IF NOT EXISTS document_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  apartment_id UUID NOT NULL,
  employee_id UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, apartment_id, employee_id)
);

-- 6. document_access_logs 테이블
CREATE TABLE IF NOT EXISTS document_access_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL,
  performed_by VARCHAR(255),
  performed_at TIMESTAMP DEFAULT NOW(),
  details JSONB
);

-- 7. document_tags 테이블
CREATE TABLE IF NOT EXISTS document_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  tag VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, tag)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_categories_active ON document_categories(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_active ON documents(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_versions_document ON document_versions(document_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_downloads_document ON document_downloads(document_id, downloaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorites_document ON document_favorites(document_id);
CREATE INDEX IF NOT EXISTS idx_favorites_apartment ON document_favorites(apartment_id, document_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_document ON document_access_logs(document_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_tags_document ON document_tags(document_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag ON document_tags(tag);

-- 트리거: updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_document_categories_updated_at
  BEFORE UPDATE ON document_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 기본 카테고리 데이터 삽입
INSERT INTO document_categories (name, description, icon, color, display_order) VALUES
  ('계약서', '입주자 및 업체 계약 관련 서류', 'fa-file-contract', 'blue', 1),
  ('공지문', '단지 공지 및 안내문', 'fa-bullhorn', 'green', 2),
  ('회계', '예산, 결산, 수지 보고서 양식', 'fa-calculator', 'yellow', 3),
  ('민원', '민원 접수 및 처리 양식', 'fa-headset', 'red', 4),
  ('점검', '시설 점검표 및 체크리스트', 'fa-clipboard-check', 'purple', 5),
  ('기타', '기타 서류', 'fa-folder', 'gray', 99)
ON CONFLICT (name) DO NOTHING;

COMMIT;

-- ============================================================
-- STEP 2: RLS 정책 설정 (Step 1 완료 후 실행!)
-- ============================================================

-- 카테고리 테이블 정책
DROP POLICY IF EXISTS "Enable read access for all users" ON document_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON document_categories;

CREATE POLICY "Enable read access for all users"
ON document_categories FOR SELECT USING (is_active = true);

CREATE POLICY "Enable insert for authenticated users"
ON document_categories FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON document_categories FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON document_categories FOR DELETE TO authenticated USING (true);

ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;

-- Storage 정책
DROP POLICY IF EXISTS "Public read access to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update in document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete from document-templates" ON storage.objects;

CREATE POLICY "Public read access to document-templates"
ON storage.objects FOR SELECT USING (bucket_id = 'document-templates');

CREATE POLICY "Authenticated upload to document-templates"
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated update in document-templates"
ON storage.objects FOR UPDATE TO authenticated 
USING (bucket_id = 'document-templates') WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated delete from document-templates"
ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'document-templates');

-- documents 테이블 정책
DROP POLICY IF EXISTS "Enable read access for all users" ON documents;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON documents;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON documents;

CREATE POLICY "Enable read access for all users"
ON documents FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users"
ON documents FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON documents FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON documents FOR DELETE TO authenticated USING (true);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- document_versions 테이블 정책
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

-- document_downloads 테이블 정책
DROP POLICY IF EXISTS "Enable read for all" ON document_downloads;
DROP POLICY IF EXISTS "Enable insert for all" ON document_downloads;

CREATE POLICY "Enable read for all"
ON document_downloads FOR SELECT USING (true);

CREATE POLICY "Enable insert for all"
ON document_downloads FOR INSERT WITH CHECK (true);

ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

-- document_favorites 테이블 정책
DROP POLICY IF EXISTS "Enable all for authenticated" ON document_favorites;

CREATE POLICY "Enable all for authenticated"
ON document_favorites FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE document_favorites ENABLE ROW LEVEL SECURITY;

-- document_access_logs 테이블 정책
DROP POLICY IF EXISTS "Enable read for all" ON document_access_logs;
DROP POLICY IF EXISTS "Enable insert for all" ON document_access_logs;

CREATE POLICY "Enable read for all"
ON document_access_logs FOR SELECT USING (true);

CREATE POLICY "Enable insert for all"
ON document_access_logs FOR INSERT WITH CHECK (true);

ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;

-- document_tags 테이블 정책
DROP POLICY IF EXISTS "Enable read for all" ON document_tags;
DROP POLICY IF EXISTS "Enable insert for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable update for authenticated" ON document_tags;
DROP POLICY IF EXISTS "Enable delete for authenticated" ON document_tags;

CREATE POLICY "Enable read for all"
ON document_tags FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated"
ON document_tags FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated"
ON document_tags FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated"
ON document_tags FOR DELETE TO authenticated USING (true);

ALTER TABLE document_tags ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 완료! 확인 쿼리
-- ============================================================

-- 1. 테이블 확인
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'document%'
ORDER BY table_name;

-- 2. 카테고리 확인
SELECT id, name, icon, color, display_order 
FROM document_categories 
ORDER BY display_order;

-- 3. RLS 정책 확인
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename LIKE 'document%'
ORDER BY tablename, policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ 8개의 테이블 생성됨
-- ✅ 6개의 기본 카테고리 삽입됨
-- ✅ 25개 이상의 RLS 정책 생성됨
--
-- ============================================================
