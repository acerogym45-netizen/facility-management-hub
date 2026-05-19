# 🚀 서류 관리 시스템 설치 가이드

> **작업 시간**: 약 5-10분  
> **필요한 것**: Supabase 대시보드 접근 권한

---

## 📌 작업 A: 데이터베이스 스키마 생성

### 1단계: SQL 파일 복사

`/home/user/webapp/database/document_system_schema.sql` 파일의 내용을 복사합니다.

### 2단계: Supabase SQL Editor 접속

1. **Supabase Dashboard** 접속
2. 왼쪽 메뉴에서 **"SQL Editor"** 클릭
3. **"New Query"** 버튼 클릭

### 3단계: SQL 실행

1. 복사한 SQL 내용을 붙여넣기
2. 우측 하단 **"Run"** 버튼 클릭 (또는 Ctrl+Enter)
3. ✅ 성공 메시지 확인: "Success. No rows returned"

### 4단계: 테이블 생성 확인

1. 왼쪽 메뉴 **"Table Editor"** 클릭
2. 다음 테이블들이 생성되었는지 확인:
   - ✅ `document_categories` (6개 기본 데이터 포함)
   - ✅ `document_templates`
   - ✅ `document_downloads`
   - ✅ `document_views`
   - ✅ `document_favorites`
   - ✅ `document_comments`
   - ✅ `document_read_status`
   - ✅ `document_notifications`

---

## 📌 작업 B: Storage 버킷 생성

### 1단계: Storage 메뉴 접속

1. Supabase Dashboard 왼쪽 메뉴
2. **"Storage"** 클릭
3. **"New bucket"** 버튼 클릭

### 2단계: 버킷 설정

**입력 정보:**
```
Name: document-templates
Public bucket: ✅ ON (체크)
File size limit: 50 MB
Allowed MIME types: (기본값 사용 또는 아래 추가)
  - application/pdf
  - application/vnd.openxmlformats-officedocument.wordprocessingml.document
  - application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  - image/png
  - image/jpeg
```

**"Create bucket"** 클릭

### 3단계: Storage 정책 설정

1. 생성된 `document-templates` 버킷 클릭
2. 상단 **"Policies"** 탭 클릭
3. **"New Policy"** 클릭

#### Policy 1: 공개 읽기 (필수)

```sql
-- 정책 이름: Public read access
-- 작업: SELECT
-- 대상: public

CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'document-templates');
```

#### Policy 2: 인증된 사용자 업로드 (필수)

```sql
-- 정책 이름: Authenticated users can upload
-- 작업: INSERT
-- 대상: authenticated

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'document-templates');
```

#### Policy 3: 인증된 사용자 삭제 (선택)

```sql
-- 정책 이름: Authenticated users can delete
-- 작업: DELETE
-- 대상: authenticated

CREATE POLICY "Authenticated users can delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'document-templates');
```

### 4단계: 버킷 생성 확인

1. Storage 메뉴에서 `document-templates` 버킷 확인
2. 버킷 클릭 → **빈 폴더 표시** (정상)
3. Policies 탭에서 3개 정책 확인

---

## ✅ 설치 완료 확인

### 체크리스트

- [ ] **8개 테이블** 생성 완료 (Table Editor에서 확인)
- [ ] **6개 기본 카테고리** 데이터 확인 (document_categories 테이블)
- [ ] **document-templates 버킷** 생성 완료
- [ ] **3개 Storage 정책** 설정 완료
- [ ] 웹 애플리케이션에서 "서류 관리" 탭 에러 없음

---

## 🔧 트러블슈팅

### 에러: "relation already exists"
→ **해결**: 이미 테이블이 존재합니다. 스킵하거나 DROP TABLE 후 재생성

### 에러: "bucket already exists"
→ **해결**: 이미 버킷이 존재합니다. 기존 버킷 사용

### 에러: "permission denied"
→ **해결**: 
1. Supabase 프로젝트 Owner 권한 확인
2. RLS 정책이 올바르게 설정되었는지 확인

### 업로드 에러: "new row violates row-level security"
→ **해결**: Storage 정책 2 (Authenticated users can upload) 재확인

---

## 📞 추가 도움이 필요하면

1. Supabase 공식 문서: https://supabase.com/docs/guides/storage
2. SQL 스키마 파일: `/home/user/webapp/database/document_system_schema.sql`
3. Storage 설정 가이드: `/home/user/webapp/database/STORAGE_SETUP.md`

---

**설치가 완료되면 웹 애플리케이션에서 "서류 업로드" 버튼을 클릭하여 테스트하세요!** 🎉
