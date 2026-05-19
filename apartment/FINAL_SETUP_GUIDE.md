# 🚀 서류 관리 시스템 - 최종 설정 가이드

## ⚡ 1분 안에 모든 문제 해결하기

현재 발생한 **모든 RLS 오류**를 한 번에 해결하는 가이드입니다.

---

## 🎯 해결할 문제들

1. ❌ 카테고리 생성 오류
   ```
   new row violates row-level security policy for table "document_categories"
   ```

2. ❌ 서류 업로드 오류
   ```
   new row violates row-level security policy for table "document_templates"
   ```

---

## ✅ 올인원 해결 방법

### Step 1: Supabase SQL Editor 열기
```
Supabase 대시보드 → SQL Editor → New Query
```

### Step 2: 아래 SQL 전체 복사 & 실행

```sql
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
```

### Step 3: "Run" 버튼 클릭
✅ **"Success. No rows returned"** 메시지 확인

### Step 4: 추가 카테고리 설치 (선택사항)
```sql
INSERT INTO document_categories (name, description, icon, color, display_order) VALUES
  ('안전관리', '안전 점검 보고서, 비상 대응 매뉴얼, 안전 교육 자료', 'fa-shield-alt', 'red', 6),
  ('시설관리', '시설물 유지보수 기록, 장비 점검 일지', 'fa-tools', 'orange', 7),
  ('법률', '법률 자문, 소송 관련 서류, 규정 문서', 'fa-gavel', 'indigo', 8),
  ('인사', '인사 규정, 근로계약서, 직원 평가서', 'fa-users', 'pink', 9),
  ('교육', '교육 자료, 매뉴얼, 교육 이수 기록', 'fa-graduation-cap', 'green', 10)
ON CONFLICT (name) DO NOTHING;
```

---

## 🧪 테스트

### 1. 카테고리 생성 테스트
1. 웹 애플리케이션 새로고침 (F5)
2. 서류 관리 → 카테고리 관리 클릭
3. "새 카테고리 추가" 클릭
4. 정보 입력 후 "저장"
5. ✅ 성공 메시지 확인

### 2. 서류 업로드 테스트
1. 서류 관리 → "서류 업로드" 클릭
2. 카테고리 선택
3. 파일 선택 (PDF, DOCX, etc.)
4. "업로드 중..." 표시
5. ✅ "서류가 업로드되었습니다" 확인

---

## ✅ 체크리스트

설정 완료 후:

- [ ] SQL 스크립트 실행 (Success 메시지 확인)
- [ ] 추가 카테고리 SQL 실행 (선택사항)
- [ ] 웹 애플리케이션 새로고침
- [ ] 카테고리 생성 테스트 → ✅ 성공
- [ ] 서류 업로드 테스트 → ✅ 성공
- [ ] 서류 목록 확인 → ✅ 파일 표시됨
- [ ] 카테고리 필터링 → ✅ 정상 작동

---

## 📊 설정 요약

### 생성된 RLS 정책 (25개+)

| 테이블 | SELECT | INSERT | UPDATE | DELETE |
|--------|--------|--------|--------|--------|
| document_categories | 모든 사용자 | 인증 | 인증 | 인증 |
| documents | 모든 사용자 | 인증 | 인증 | 인증 |
| document_versions | 모든 사용자 | 인증 | 인증 | 인증 |
| document_downloads | 모든 사용자 | 모든 사용자 | - | - |
| document_favorites | 인증 | 인증 | 인증 | 인증 |
| document_access_logs | 모든 사용자 | 모든 사용자 | - | - |
| document_tags | 모든 사용자 | 인증 | 인증 | 인증 |
| storage.objects | 모든 사용자 | 인증 | 인증 | 인증 |

---

## 🎉 완료!

이제 **서류 관리 시스템**의 모든 기능이 정상 작동합니다:

### 사용 가능한 기능
1. ✅ 카테고리 생성/수정/삭제
2. ✅ 서류 업로드
3. ✅ 서류 다운로드
4. ✅ 서류 삭제
5. ✅ 서류 검색 및 필터링
6. ✅ 즐겨찾기 추가/제거
7. ✅ 버전 관리
8. ✅ 다운로드 통계
9. ✅ 접근 로그
10. ✅ 태그 관리

---

## 📂 관련 파일

- **`database/COMPLETE_RLS_SETUP.sql`** - 전체 RLS 정책 (상세 주석 포함)
- **`database/FIX_CATEGORY_RLS_POLICY.sql`** - 카테고리 전용 정책
- **`database/FIX_STORAGE_RLS_POLICY.sql`** - 스토리지 전용 정책
- **`database/ADDITIONAL_CATEGORIES.sql`** - 추가 카테고리 5개

---

## 🆘 문제가 계속되면?

1. **브라우저 콘솔 확인** (F12 → Console)
2. **Network 탭 확인** (F12 → Network)
3. **Supabase 로그 확인** (Dashboard → Logs)
4. **정책 확인 쿼리 실행**:
   ```sql
   SELECT tablename, policyname, cmd, roles
   FROM pg_policies 
   WHERE tablename LIKE 'document%'
   ORDER BY tablename, policyname;
   ```

---

**이제 모든 기능을 사용할 수 있습니다! 🎊**

문제가 해결되었는지 테스트해보세요! 😊
