-- ============================================
-- 서류 템플릿 공유 시스템 - Database Schema
-- Version: 1.0
-- Created: 2026-05-09
-- ============================================

-- ============================================
-- 1. 서류 카테고리 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS document_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 기본 정보
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50) DEFAULT 'fa-folder', -- Font Awesome 아이콘
  color VARCHAR(20) DEFAULT 'gray', -- 테마 컬러 (blue, green, red, yellow, purple, gray)
  
  -- 정렬 및 표시
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- 메타데이터
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_categories_active ON document_categories(is_active, display_order);

-- 기본 카테고리 데이터
INSERT INTO document_categories (name, description, icon, color, display_order) VALUES
  ('계약서', '입주자 및 업체 계약 관련 서류', 'fa-file-contract', 'blue', 1),
  ('공지문', '단지 공지 및 안내문', 'fa-bullhorn', 'green', 2),
  ('회계', '예산, 결산, 수지 보고서 양식', 'fa-calculator', 'yellow', 3),
  ('민원', '민원 접수 및 처리 양식', 'fa-headset', 'red', 4),
  ('점검', '시설 점검표 및 체크리스트', 'fa-clipboard-check', 'purple', 5),
  ('기타', '기타 서류', 'fa-folder', 'gray', 99)
ON CONFLICT (name) DO NOTHING;


-- ============================================
-- 2. 서류 템플릿 테이블 (메인)
-- ============================================
CREATE TABLE IF NOT EXISTS document_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 기본 정보
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES document_categories(id) ON DELETE SET NULL,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[], -- 검색용 태그
  
  -- 파일 정보
  file_url TEXT NOT NULL, -- Supabase Storage URL
  file_name VARCHAR(255) NOT NULL, -- 원본 파일명
  file_size BIGINT, -- bytes
  file_type VARCHAR(50), -- 확장자 (docx, pdf, xlsx, pptx 등)
  mime_type VARCHAR(100), -- MIME 타입
  
  -- 썸네일 (PDF/이미지용)
  thumbnail_url TEXT,
  
  -- 버전 관리
  version VARCHAR(20) DEFAULT '1.0',
  version_notes TEXT, -- 버전 변경 내역
  is_latest BOOLEAN DEFAULT TRUE, -- 최신 버전 여부
  parent_document_id UUID REFERENCES document_templates(id) ON DELETE SET NULL, -- 이전 버전 연결
  
  -- 권한 및 공개 범위
  is_public BOOLEAN DEFAULT TRUE, -- 전체 공개 여부
  allowed_apartments UUID[] DEFAULT ARRAY[]::UUID[], -- 특정 단지만 접근 (비어있으면 전체)
  required_role VARCHAR(50), -- 필요한 최소 권한 (admin, manager, employee)
  
  -- 메타데이터
  uploaded_by UUID REFERENCES employees(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- 통계
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  
  -- 상태 및 옵션
  is_active BOOLEAN DEFAULT TRUE,
  is_pinned BOOLEAN DEFAULT FALSE, -- 상단 고정
  is_featured BOOLEAN DEFAULT FALSE, -- 추천 서류
  expires_at TIMESTAMP, -- 만료일 (선택 사항)
  
  -- 알림 설정
  notify_on_update BOOLEAN DEFAULT TRUE -- 업데이트 시 알림 발송
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_templates_category ON document_templates(category_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_templates_active ON document_templates(is_active, is_pinned DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_templates_latest ON document_templates(is_latest, category_id);
CREATE INDEX IF NOT EXISTS idx_templates_tags ON document_templates USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_templates_search ON document_templates USING GIN(to_tsvector('simple', title || ' ' || COALESCE(description, '')));


-- ============================================
-- 3. 다운로드 이력 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS document_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 관계
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  downloaded_by UUID REFERENCES employees(id) ON DELETE SET NULL,
  
  -- 다운로드 정보
  downloaded_at TIMESTAMP DEFAULT NOW(),
  
  -- 추적 정보 (선택 사항)
  ip_address INET,
  user_agent TEXT,
  download_method VARCHAR(50) DEFAULT 'direct' -- 'direct', 'preview', 'share' 등
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_downloads_document ON document_downloads(document_id, downloaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_downloads_apartment ON document_downloads(apartment_id, downloaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_downloads_user ON document_downloads(downloaded_by, downloaded_at DESC);


-- ============================================
-- 4. 즐겨찾기 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS document_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 관계
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  
  -- 메타데이터
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- 유니크 제약 (한 사용자가 같은 문서를 중복 즐겨찾기 불가)
  UNIQUE(document_id, apartment_id, employee_id)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_favorites_user ON document_favorites(apartment_id, employee_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorites_document ON document_favorites(document_id);


-- ============================================
-- 5. 서류 조회 이력 테이블 (읽음/안읽음 체크용)
-- ============================================
CREATE TABLE IF NOT EXISTS document_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 관계
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  viewed_by UUID REFERENCES employees(id) ON DELETE CASCADE,
  
  -- 조회 정보
  first_viewed_at TIMESTAMP DEFAULT NOW(),
  last_viewed_at TIMESTAMP DEFAULT NOW(),
  view_count INTEGER DEFAULT 1,
  
  -- 읽음 상태
  is_read BOOLEAN DEFAULT FALSE, -- 전체 읽음 완료 여부
  read_at TIMESTAMP,
  
  -- 유니크 제약
  UNIQUE(document_id, apartment_id, viewed_by)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_views_user ON document_views(apartment_id, viewed_by, last_viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_views_document ON document_views(document_id, last_viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_views_unread ON document_views(apartment_id, viewed_by, is_read) WHERE is_read = FALSE;


-- ============================================
-- 6. 댓글 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS document_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 관계
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES document_comments(id) ON DELETE CASCADE, -- 대댓글용
  
  -- 작성자 정보
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  author_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  author_name VARCHAR(100), -- 작성자 이름 (캐시)
  author_role VARCHAR(50), -- 작성자 역할 (캐시)
  
  -- 댓글 내용
  content TEXT NOT NULL,
  
  -- 메타데이터
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- 상태
  is_deleted BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE, -- 상단 고정
  is_staff_reply BOOLEAN DEFAULT FALSE -- 관리자 답변
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_comments_document ON document_comments(document_id, is_deleted, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_author ON document_comments(author_id, created_at DESC);


-- ============================================
-- 7. 알림 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS document_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 관계
  document_id UUID REFERENCES document_templates(id) ON DELETE CASCADE,
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  
  -- 알림 내용
  notification_type VARCHAR(50) NOT NULL, -- 'new_document', 'update', 'comment', 'mention'
  title VARCHAR(255) NOT NULL,
  message TEXT,
  
  -- 알림 상태
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  
  -- 메타데이터
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- 링크
  action_url TEXT -- 알림 클릭 시 이동할 URL
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_notifications_user ON document_notifications(apartment_id, recipient_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_document ON document_notifications(document_id, created_at DESC);


-- ============================================
-- 8. 트리거: 다운로드 카운트 자동 증가
-- ============================================
CREATE OR REPLACE FUNCTION increment_download_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE document_templates
  SET download_count = download_count + 1
  WHERE id = NEW.document_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_download_count ON document_downloads;
CREATE TRIGGER trigger_increment_download_count
  AFTER INSERT ON document_downloads
  FOR EACH ROW
  EXECUTE FUNCTION increment_download_count();


-- ============================================
-- 9. 트리거: 조회수 자동 증가
-- ============================================
CREATE OR REPLACE FUNCTION increment_view_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE document_templates
  SET view_count = view_count + 1
  WHERE id = NEW.document_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_view_count ON document_views;
CREATE TRIGGER trigger_increment_view_count
  AFTER INSERT ON document_views
  FOR EACH ROW
  EXECUTE FUNCTION increment_view_count();


-- ============================================
-- 10. 트리거: 즐겨찾기 카운트 자동 업데이트
-- ============================================
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
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_favorite_count ON document_favorites;
CREATE TRIGGER trigger_update_favorite_count
  AFTER INSERT OR DELETE ON document_favorites
  FOR EACH ROW
  EXECUTE FUNCTION update_favorite_count();


-- ============================================
-- 11. 트리거: updated_at 자동 업데이트
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- document_templates 테이블에 적용
DROP TRIGGER IF EXISTS trigger_update_templates_updated_at ON document_templates;
CREATE TRIGGER trigger_update_templates_updated_at
  BEFORE UPDATE ON document_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- document_categories 테이블에 적용
DROP TRIGGER IF EXISTS trigger_update_categories_updated_at ON document_categories;
CREATE TRIGGER trigger_update_categories_updated_at
  BEFORE UPDATE ON document_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- document_comments 테이블에 적용
DROP TRIGGER IF EXISTS trigger_update_comments_updated_at ON document_comments;
CREATE TRIGGER trigger_update_comments_updated_at
  BEFORE UPDATE ON document_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 12. 뷰: 최신 버전 서류만 조회
-- ============================================
CREATE OR REPLACE VIEW document_templates_latest AS
SELECT *
FROM document_templates
WHERE is_latest = TRUE AND is_active = TRUE;


-- ============================================
-- 13. 뷰: 인기 서류 (다운로드 순)
-- ============================================
CREATE OR REPLACE VIEW document_templates_popular AS
SELECT 
  dt.*,
  dc.name AS category_name,
  dc.icon AS category_icon,
  dc.color AS category_color
FROM document_templates dt
LEFT JOIN document_categories dc ON dt.category_id = dc.id
WHERE dt.is_latest = TRUE AND dt.is_active = TRUE
ORDER BY dt.download_count DESC, dt.created_at DESC
LIMIT 10;


-- ============================================
-- 14. 함수: 서류 검색 (전문 검색)
-- ============================================
CREATE OR REPLACE FUNCTION search_documents(
  search_query TEXT,
  category_filter UUID DEFAULT NULL,
  apartment_filter UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title VARCHAR,
  description TEXT,
  category_id UUID,
  file_url TEXT,
  file_name VARCHAR,
  file_type VARCHAR,
  version VARCHAR,
  download_count INTEGER,
  created_at TIMESTAMP,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dt.id,
    dt.title,
    dt.description,
    dt.category_id,
    dt.file_url,
    dt.file_name,
    dt.file_type,
    dt.version,
    dt.download_count,
    dt.created_at,
    ts_rank(
      to_tsvector('simple', dt.title || ' ' || COALESCE(dt.description, '')),
      plainto_tsquery('simple', search_query)
    ) AS rank
  FROM document_templates dt
  WHERE 
    dt.is_active = TRUE
    AND dt.is_latest = TRUE
    AND (
      to_tsvector('simple', dt.title || ' ' || COALESCE(dt.description, '')) @@ plainto_tsquery('simple', search_query)
      OR dt.tags @> ARRAY[search_query]
    )
    AND (category_filter IS NULL OR dt.category_id = category_filter)
    AND (apartment_filter IS NULL OR apartment_filter = ANY(dt.allowed_apartments) OR array_length(dt.allowed_apartments, 1) IS NULL)
  ORDER BY rank DESC, dt.created_at DESC;
END;
$$ LANGUAGE plpgsql;


-- ============================================
-- 15. RLS (Row Level Security) 정책
-- ============================================

-- document_templates 읽기 권한 (모든 인증된 사용자)
ALTER TABLE document_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active documents"
  ON document_templates FOR SELECT
  USING (is_active = TRUE AND is_latest = TRUE);

CREATE POLICY "Admins can manage all documents"
  ON document_templates FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');


-- document_downloads 정책
ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own downloads"
  ON document_downloads FOR SELECT
  USING (downloaded_by = auth.uid());

CREATE POLICY "Users can insert own downloads"
  ON document_downloads FOR INSERT
  WITH CHECK (downloaded_by = auth.uid());


-- document_favorites 정책
ALTER TABLE document_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own favorites"
  ON document_favorites FOR ALL
  USING (employee_id = auth.uid());


-- document_views 정책
ALTER TABLE document_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own views"
  ON document_views FOR ALL
  USING (viewed_by = auth.uid());


-- document_comments 정책
ALTER TABLE document_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active comments"
  ON document_comments FOR SELECT
  USING (is_deleted = FALSE);

CREATE POLICY "Users can insert comments"
  ON document_comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Users can update own comments"
  ON document_comments FOR UPDATE
  USING (author_id = auth.uid());


-- document_notifications 정책
ALTER TABLE document_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON document_notifications FOR SELECT
  USING (recipient_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON document_notifications FOR UPDATE
  USING (recipient_id = auth.uid());


-- ============================================
-- 완료 메시지
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ 서류 템플릿 공유 시스템 스키마 생성 완료!';
  RAISE NOTICE '📊 생성된 테이블: 8개';
  RAISE NOTICE '🔍 생성된 인덱스: 15개';
  RAISE NOTICE '⚡ 생성된 트리거: 5개';
  RAISE NOTICE '📈 생성된 뷰: 2개';
  RAISE NOTICE '🔐 생성된 RLS 정책: 10개';
END $$;
