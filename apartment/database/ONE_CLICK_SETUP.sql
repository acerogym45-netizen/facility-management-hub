-- ============================================
-- 🚀 원클릭 설치 스크립트
-- 서류 관리 시스템 - 데이터베이스 + Storage
-- ============================================
-- 
-- 사용법:
-- 1. 이 파일 전체를 복사
-- 2. Supabase SQL Editor에 붙여넣기
-- 3. Run 버튼 클릭
--
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: 테이블 생성
-- ============================================

-- 1.1 서류 카테고리
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

CREATE INDEX IF NOT EXISTS idx_categories_active ON document_categories(is_active, display_order);

-- 1.2 서류 템플릿
CREATE TABLE IF NOT EXISTS document_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES document_categories(id) ON DELETE SET NULL,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  file_url TEXT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size BIGINT,
  file_type VARCHAR(50),
  mime_type VARCHAR(100),
  thumbnail_url TEXT,
  version VARCHAR(20) DEFAULT '1.0',
  version_notes TEXT,
  is_latest BOOLEAN DEFAULT TRUE,
  parent_document_id UUID REFERENCES document_templates(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT TRUE,
  allowed_apartments UUID[] DEFAULT ARRAY[]::UUID[],
  required_role VARCHAR(50),
  uploaded_by UUID REFERENCES employees(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP,
  notify_on_update BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_templates_category ON document_templates(category_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_templates_active ON document_templates(is_active, is_pinned DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_templates_latest ON document_templates(is_latest, category_id);
CREATE INDEX IF NOT EXISTS idx_templates_tags ON document_templates USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_templates_search ON document_templates USING GIN(to_tsvector('simple', title || ' ' || COALESCE(description, '')));

-- 1.3 다운로드 기록
CREATE TABLE IF NOT EXISTS document_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  downloaded_by UUID REFERENCES employees(id) ON DELETE SET NULL,
  downloaded_at TIMESTAMP DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_downloads_document ON document_downloads(document_id, downloaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_downloads_user ON document_downloads(downloaded_by, downloaded_at DESC);

-- 1.4 조회 기록
CREATE TABLE IF NOT EXISTS document_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  viewed_by UUID REFERENCES employees(id) ON DELETE SET NULL,
  viewed_at TIMESTAMP DEFAULT NOW(),
  view_duration INTEGER DEFAULT 0,
  ip_address INET
);

CREATE INDEX IF NOT EXISTS idx_views_document ON document_views(document_id, viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_views_user ON document_views(viewed_by, viewed_at DESC);

-- 1.5 즐겨찾기
CREATE TABLE IF NOT EXISTS document_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON document_favorites(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorites_document ON document_favorites(document_id);

-- 1.6 댓글
CREATE TABLE IF NOT EXISTS document_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_comment_id UUID REFERENCES document_comments(id) ON DELETE CASCADE,
  is_edited BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_document ON document_comments(document_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_user ON document_comments(user_id, created_at DESC);

-- 1.7 읽음 상태
CREATE TABLE IF NOT EXISTS document_read_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_read_status_user ON document_read_status(user_id, is_read);

-- 1.8 알림
CREATE TABLE IF NOT EXISTS document_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  user_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  notification_type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON document_notifications(user_id, is_read, created_at DESC);

-- ============================================
-- STEP 2: 기본 데이터 삽입
-- ============================================

INSERT INTO document_categories (name, description, icon, color, display_order) VALUES
  ('계약서', '입주자 및 업체 계약 관련 서류', 'fa-file-contract', 'blue', 1),
  ('공지문', '단지 공지 및 안내문', 'fa-bullhorn', 'green', 2),
  ('회계', '예산, 결산, 수지 보고서 양식', 'fa-calculator', 'yellow', 3),
  ('민원', '민원 접수 및 처리 양식', 'fa-headset', 'red', 4),
  ('점검', '시설 점검표 및 체크리스트', 'fa-clipboard-check', 'purple', 5),
  ('기타', '기타 서류', 'fa-folder', 'gray', 99)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- STEP 3: 트리거 생성
-- ============================================

-- 3.1 다운로드 카운터
CREATE OR REPLACE FUNCTION increment_download_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE document_templates
  SET download_count = download_count + 1
  WHERE id = NEW.document_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_download ON document_downloads;
CREATE TRIGGER trigger_increment_download
AFTER INSERT ON document_downloads
FOR EACH ROW EXECUTE FUNCTION increment_download_count();

-- 3.2 조회 카운터
CREATE OR REPLACE FUNCTION increment_view_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE document_templates
  SET view_count = view_count + 1
  WHERE id = NEW.document_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_view ON document_views;
CREATE TRIGGER trigger_increment_view
AFTER INSERT ON document_views
FOR EACH ROW EXECUTE FUNCTION increment_view_count();

-- 3.3 즐겨찾기 카운터
CREATE OR REPLACE FUNCTION update_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE document_templates
    SET favorite_count = favorite_count + 1
    WHERE id = NEW.document_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE document_templates
    SET favorite_count = favorite_count - 1
    WHERE id = OLD.document_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_favorite_insert ON document_favorites;
CREATE TRIGGER trigger_favorite_insert
AFTER INSERT ON document_favorites
FOR EACH ROW EXECUTE FUNCTION update_favorite_count();

DROP TRIGGER IF EXISTS trigger_favorite_delete ON document_favorites;
CREATE TRIGGER trigger_favorite_delete
AFTER DELETE ON document_favorites
FOR EACH ROW EXECUTE FUNCTION update_favorite_count();

-- ============================================
-- STEP 4: Storage 정책 (수동 설정 필요)
-- ============================================

-- 아래 정책들은 Storage 메뉴에서 수동으로 설정해야 합니다:
-- 
-- 1. Supabase Dashboard → Storage → New bucket
--    - Name: document-templates
--    - Public: ON
--
-- 2. Policies 탭에서 아래 정책 추가:

-- Policy 1: Public read
-- CREATE POLICY "Public read access"
-- ON storage.objects FOR SELECT
-- TO public
-- USING (bucket_id = 'document-templates');

-- Policy 2: Authenticated upload
-- CREATE POLICY "Authenticated users can upload"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'document-templates');

-- Policy 3: Authenticated delete
-- CREATE POLICY "Authenticated users can delete"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'document-templates');

COMMIT;

-- ============================================
-- ✅ 설치 완료!
-- ============================================
-- 
-- 다음 단계:
-- 1. Storage 메뉴에서 document-templates 버킷 생성
-- 2. Storage 정책 3개 추가
-- 3. 웹 애플리케이션 새로고침
-- 
-- ============================================
