# 🚨 "relation documents does not exist" 오류 해결

## ❌ 문제
```
Error: Failed to run sql query: ERROR: 42P01:
relation "documents" does not exist
```

## 🔍 원인
**테이블이 아직 생성되지 않았습니다!**

RLS 정책을 설정하기 전에 먼저 데이터베이스 테이블을 생성해야 합니다.

---

## ✅ 올바른 설치 순서

### 📌 중요: 다음 순서대로 진행하세요!

1. ✅ **STEP 1**: 테이블 생성 (먼저!)
2. ✅ **STEP 2**: RLS 정책 설정 (나중에!)

---

## 🚀 해결 방법

### STEP 1: 테이블 생성 (먼저 실행!)

#### Supabase SQL Editor에서 다음 SQL 실행:

```sql
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

-- 2. documents 테이블
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
```

#### "Run" 클릭 → ✅ Success 확인!

---

### STEP 2: RLS 정책 설정 (STEP 1 완료 후 실행!)

위의 STEP 1이 성공한 후, 이제 RLS 정책을 설정합니다:

```sql
-- 카테고리 테이블 정책
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
CREATE POLICY "Enable read for all"
ON document_downloads FOR SELECT USING (true);

CREATE POLICY "Enable insert for all"
ON document_downloads FOR INSERT WITH CHECK (true);

ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

-- document_favorites 테이블 정책
CREATE POLICY "Enable all for authenticated"
ON document_favorites FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE document_favorites ENABLE ROW LEVEL SECURITY;

-- document_access_logs 테이블 정책
CREATE POLICY "Enable read for all"
ON document_access_logs FOR SELECT USING (true);

CREATE POLICY "Enable insert for all"
ON document_access_logs FOR INSERT WITH CHECK (true);

ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;

-- document_tags 테이블 정책
CREATE POLICY "Enable read for all"
ON document_tags FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated"
ON document_tags FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated"
ON document_tags FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated"
ON document_tags FOR DELETE TO authenticated USING (true);

ALTER TABLE document_tags ENABLE ROW LEVEL SECURITY;
```

#### "Run" 클릭 → ✅ Success 확인!

---

## ✅ 확인

### 테이블 생성 확인
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'document%'
ORDER BY table_name;
```

**예상 결과**: 7개 테이블
- document_access_logs
- document_categories
- document_downloads
- document_favorites
- document_tags
- document_versions
- documents

### 카테고리 확인
```sql
SELECT name, icon, color 
FROM document_categories 
ORDER BY display_order;
```

**예상 결과**: 6개 카테고리

### RLS 정책 확인
```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE tablename LIKE 'document%'
ORDER BY tablename;
```

**예상 결과**: 25개 이상의 정책

---

## 📂 전체 스크립트 파일

**`database/STEP_BY_STEP_SETUP.sql`** 파일에 위의 모든 SQL이 순서대로 정리되어 있습니다.

---

## 🎉 완료 후 테스트

1. 웹 애플리케이션 새로고침 (F5)
2. 서류 관리 탭 클릭
3. 카테고리 관리 → 6개 카테고리 확인 ✅
4. 새 카테고리 추가 테스트 ✅
5. 서류 업로드 테스트 ✅

---

## 📋 체크리스트

- [ ] STEP 1 SQL 실행 (테이블 생성)
- [ ] Success 메시지 확인
- [ ] 테이블 확인 쿼리 실행
- [ ] 7개 테이블 생성 확인
- [ ] 6개 카테고리 삽입 확인
- [ ] STEP 2 SQL 실행 (RLS 정책)
- [ ] Success 메시지 확인
- [ ] RLS 정책 확인 쿼리 실행
- [ ] 웹 애플리케이션 테스트
- [ ] ✅ 모든 기능 정상 작동!

---

**STEP 1부터 차근차근 진행하세요! 🚀**

문제가 계속되면 오류 메시지를 알려주세요! 😊
