-- ============================================================
-- 서류 관리 시스템 - 간단 버전 (apartment_id 제거)
-- Simple Document Management System Setup
-- ============================================================

BEGIN;

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. document_categories 테이블
-- ============================================================
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

-- ============================================================
-- 2. documents 테이블 (apartment_id 제거)
-- ============================================================
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
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  download_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 3. document_versions 테이블
-- ============================================================
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

-- ============================================================
-- 4. document_downloads 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS document_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  downloaded_by VARCHAR(255),
  downloaded_at TIMESTAMP DEFAULT NOW(),
  ip_address INET
);

-- ============================================================
-- 5. document_favorites 테이블 (apartment_id 제거)
-- ============================================================
CREATE TABLE IF NOT EXISTS document_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  user_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, user_id)
);

-- ============================================================
-- 6. document_access_logs 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS document_access_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL,
  performed_by VARCHAR(255),
  performed_at TIMESTAMP DEFAULT NOW(),
  details JSONB
);

-- ============================================================
-- 7. document_tags 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS document_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  tag VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, tag)
);

-- ============================================================
-- 인덱스 생성
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_categories_active ON document_categories(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_active ON documents(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_versions_document ON document_versions(document_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_downloads_document ON document_downloads(document_id, downloaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorites_document ON document_favorites(document_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_document ON document_access_logs(document_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_tags_document ON document_tags(document_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag ON document_tags(tag);

-- ============================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS update_document_categories_updated_at ON document_categories;
CREATE TRIGGER update_document_categories_updated_at
  BEFORE UPDATE ON document_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 기본 카테고리 데이터 삽입
-- ============================================================
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
-- 확인 쿼리
-- ============================================================

-- 테이블 확인
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'document%'
ORDER BY table_name;

-- 카테고리 확인
SELECT id, name, icon, color, display_order 
FROM document_categories 
ORDER BY display_order;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ 7개 테이블 생성:
--    - document_access_logs
--    - document_categories
--    - document_downloads
--    - document_favorites
--    - document_tags
--    - document_versions
--    - documents
--
-- ✅ 6개 기본 카테고리 삽입
--
-- ============================================================
