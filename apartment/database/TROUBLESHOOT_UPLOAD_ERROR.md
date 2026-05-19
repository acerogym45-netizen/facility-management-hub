# 🚨 서류 업로드 오류 해결 가이드

## ❌ 발생한 오류
```
new row violates row-level security policy for table "document_templates"
```

## 🔍 원인
Supabase **Storage** 버킷의 RLS 정책이 설정되어 있지 않아서 파일을 업로드할 수 없습니다.

---

## ✅ 빠른 해결 방법 (2가지)

### 🎯 방법 1: SQL로 한 번에 해결 (권장) ⭐

#### Step 1: Supabase SQL Editor 열기
```
Supabase 대시보드 → SQL Editor → New Query
```

#### Step 2: 다음 SQL 복사 & 실행

```sql
-- Storage 정책 생성 (document-templates 버킷)
DROP POLICY IF EXISTS "Public read access to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload to document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update in document-templates" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete from document-templates" ON storage.objects;

CREATE POLICY "Public read access to document-templates"
ON storage.objects FOR SELECT
USING (bucket_id = 'document-templates');

CREATE POLICY "Authenticated upload to document-templates"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated update in document-templates"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'document-templates')
WITH CHECK (bucket_id = 'document-templates');

CREATE POLICY "Authenticated delete from document-templates"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'document-templates');

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
```

#### Step 3: "Run" 버튼 클릭
✅ Success 메시지 확인

#### Step 4: 웹 애플리케이션에서 다시 업로드 테스트
이제 파일 업로드가 정상적으로 작동합니다! 🎉

---

### 🎯 방법 2: Supabase Dashboard에서 설정

#### Step 1: Storage 페이지로 이동
```
Supabase 대시보드 → Storage → document-templates
```

#### Step 2: Policies 탭 클릭
```
document-templates 버킷 클릭 → "Policies" 탭
```

#### Step 3: 정책 추가

**정책 1: Public Read Access**
```
Policy name: Public read access
Allowed operation: SELECT
Target roles: public
USING expression: bucket_id = 'document-templates'
```

**정책 2: Authenticated Upload**
```
Policy name: Authenticated upload
Allowed operation: INSERT
Target roles: authenticated
WITH CHECK expression: bucket_id = 'document-templates'
```

**정책 3: Authenticated Update**
```
Policy name: Authenticated update
Allowed operation: UPDATE
Target roles: authenticated
USING expression: bucket_id = 'document-templates'
WITH CHECK expression: bucket_id = 'document-templates'
```

**정책 4: Authenticated Delete**
```
Policy name: Authenticated delete
Allowed operation: DELETE
Target roles: authenticated
USING expression: bucket_id = 'document-templates'
```

---

## 📋 설정된 정책 설명

### Storage 정책 (storage.objects)

| 정책 | 대상 | 설명 |
|------|------|------|
| **SELECT** | 모든 사용자 | document-templates 버킷의 파일 조회 가능 |
| **INSERT** | 인증된 사용자 | 파일 업로드 가능 |
| **UPDATE** | 인증된 사용자 | 파일 메타데이터 수정 가능 |
| **DELETE** | 인증된 사용자 | 파일 삭제 가능 |

### 테이블 정책

| 테이블 | 정책 | 설명 |
|--------|------|------|
| **documents** | SELECT (모든 사용자) | 서류 목록 조회 |
| | INSERT/UPDATE/DELETE (인증) | 서류 관리 |
| **document_versions** | SELECT (모든 사용자) | 버전 이력 조회 |
| | INSERT/UPDATE/DELETE (인증) | 버전 관리 |
| **document_downloads** | SELECT/INSERT (모든 사용자) | 다운로드 기록 |
| **document_favorites** | ALL (인증된 사용자) | 즐겨찾기 관리 |

---

## 🔍 정책 확인 방법

### 1. Storage 정책 확인
```sql
SELECT policyname, cmd, roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%document-templates%';
```

**예상 결과**: 4개의 정책

### 2. 테이블 정책 확인
```sql
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE tablename IN ('documents', 'document_versions', 'document_downloads', 'document_favorites')
ORDER BY tablename, policyname;
```

**예상 결과**: 각 테이블마다 여러 개의 정책

---

## 🧪 테스트 시나리오

### 1. 파일 업로드 테스트
1. 서류 관리 탭 → "서류 업로드" 버튼 클릭
2. 카테고리 선택
3. 파일 선택 (PDF, DOCX, etc.)
4. "업로드 중..." 표시
5. ✅ "서류가 업로드되었습니다" 메시지 확인

### 2. 업로드된 파일 확인
```sql
SELECT name, bucket_id, created_at
FROM storage.objects 
WHERE bucket_id = 'document-templates'
ORDER BY created_at DESC;
```

### 3. documents 테이블 확인
```sql
SELECT id, title, category_id, file_url, uploaded_by
FROM documents
ORDER BY created_at DESC
LIMIT 5;
```

---

## 📝 체크리스트

해결 후 다음을 확인하세요:

- [ ] SQL 스크립트 실행 완료 (Success 메시지)
- [ ] Storage 정책 4개 생성 확인
- [ ] documents 테이블 정책 4개 생성 확인
- [ ] document_versions 정책 4개 생성 확인
- [ ] document_downloads 정책 2개 생성 확인
- [ ] document_favorites 정책 1개 생성 확인
- [ ] 웹 애플리케이션 새로고침 (F5)
- [ ] 서류 업로드 모달 열기
- [ ] 카테고리 선택
- [ ] 파일 선택 및 업로드
- [ ] ✅ 업로드 성공 메시지 확인
- [ ] 서류 목록에 새 파일 표시 확인

---

## 🆘 여전히 오류가 발생하나요?

### 추가 확인 사항:

#### 1. 버킷 존재 확인
```sql
SELECT * FROM storage.buckets WHERE name = 'document-templates';
```
- 결과가 없으면 버킷을 다시 생성해야 합니다

#### 2. 버킷이 public인지 확인
```sql
SELECT name, public FROM storage.buckets WHERE name = 'document-templates';
```
- `public = true`여야 합니다

#### 3. 버킷이 없다면 생성
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('document-templates', 'document-templates', true)
ON CONFLICT (id) DO NOTHING;
```

#### 4. 브라우저 콘솔 확인
- F12 → Console 탭
- 업로드 시도 중 발생하는 오류 메시지 확인

#### 5. Network 탭 확인
- F12 → Network 탭
- 업로드 요청의 상태 코드 확인 (401, 403, 500 등)

---

## 🔐 RLS 정책 이해하기

### Storage RLS vs Table RLS

| 구분 | Storage (storage.objects) | Table (documents) |
|------|--------------------------|-------------------|
| **대상** | 파일 업로드/삭제 | 데이터 CRUD |
| **조건** | bucket_id로 구분 | 테이블별로 설정 |
| **역할** | public / authenticated | public / authenticated |

### 인증 상태 확인

웹 애플리케이션에서 Supabase를 사용하면:
- **익명 (anon)**: 로그인하지 않은 상태
- **인증 (authenticated)**: Supabase 클라이언트로 초기화한 상태

현재 코드는 `authenticated` 역할로 작동합니다.

---

## 📂 관련 파일

- **`database/FIX_STORAGE_RLS_POLICY.sql`** - 상세 SQL 스크립트 (주석 포함)
- **`database/ONE_CLICK_SETUP.sql`** - 전체 데이터베이스 설정

---

## 🎉 해결 완료 후

정책이 정상적으로 설정되면:
1. ✅ 파일 업로드 가능
2. ✅ 파일 다운로드 가능
3. ✅ 파일 삭제 가능
4. ✅ 서류 관리 기능 완전히 작동

---

## 💡 추가 팁

### 파일 크기 제한
Supabase Storage는 기본적으로 50MB까지 업로드 가능합니다.
더 큰 파일이 필요하면 Supabase 프로젝트 설정에서 조정하세요.

### 허용된 파일 형식
현재 설정: PDF, DOCX, XLSX, PPTX, PNG, JPG (최대 50MB)

---

**위 SQL을 실행하면 모든 문제가 해결됩니다! 🚀**

추가 문제가 발생하면 알려주세요! 😊
