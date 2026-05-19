-- ============================================
-- 브랜드 설정 테이블 (기업별 커스터마이징)
-- ============================================

-- 브랜드 설정 테이블 생성
CREATE TABLE IF NOT EXISTS brand_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name TEXT NOT NULL DEFAULT '마스터플랜리소스(유)',
  company_name_en TEXT DEFAULT 'MasterPlanResource Co.,Ltd.',
  logo_url TEXT, -- 로고 이미지 URL (Supabase Storage 또는 외부 URL)
  primary_color TEXT DEFAULT '#2C5F2D', -- 메인 브랜드 컬러
  secondary_color TEXT DEFAULT '#4CAF50', -- 보조 브랜드 컬러
  favicon_url TEXT, -- 파비콘 URL
  login_subtitle TEXT DEFAULT '직원 업무 관리 시스템',
  master_dashboard_title TEXT DEFAULT '총괄 관리자',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 기본 브랜드 설정 삽입 (마스터플랜리소스)
INSERT INTO brand_settings (
  company_name,
  company_name_en,
  primary_color,
  secondary_color,
  login_subtitle,
  master_dashboard_title
) VALUES (
  '마스터플랜리소스(유)',
  'MasterPlanResource Co.,Ltd.',
  '#C5A35F', -- 골드 색상 (로고에 맞춤)
  '#D4AF37',
  '직원 업무 관리 시스템',
  '총괄 관리자'
) ON CONFLICT DO NOTHING;

-- RLS 정책 설정
ALTER TABLE brand_settings ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽을 수 있도록 (공개)
CREATE POLICY "Enable read access for all users"
ON brand_settings FOR SELECT
USING (true);

-- 인증된 사용자만 수정 가능
CREATE POLICY "Enable update for authenticated users only"
ON brand_settings FOR UPDATE
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- anon 사용자도 읽을 수 있도록 추가 정책
CREATE POLICY "Enable read access for anon"
ON brand_settings FOR SELECT
TO anon
USING (true);

-- 주석
COMMENT ON TABLE brand_settings IS '기업별 브랜드 설정 (로고, 색상, 텍스트 등)';
COMMENT ON COLUMN brand_settings.company_name IS '회사명 (한글)';
COMMENT ON COLUMN brand_settings.company_name_en IS '회사명 (영문)';
COMMENT ON COLUMN brand_settings.logo_url IS '로고 이미지 URL';
COMMENT ON COLUMN brand_settings.primary_color IS '메인 브랜드 색상 (HEX)';
COMMENT ON COLUMN brand_settings.secondary_color IS '보조 브랜드 색상 (HEX)';
COMMENT ON COLUMN brand_settings.login_subtitle IS '로그인 화면 부제목';
COMMENT ON COLUMN brand_settings.master_dashboard_title IS '총괄 관리자 페이지 타이틀';
