# 🚨 카테고리 생성 오류 해결 가이드

## ❌ 발생한 오류
```
new row violates row-level security policy for table "document_categories"
```

## 🔍 원인
Supabase의 **Row Level Security (RLS)** 정책이 설정되어 있지 않아서 카테고리를 생성/수정/삭제할 수 없습니다.

---

## ✅ 해결 방법 (2가지)

### 🎯 방법 1: RLS 정책 추가 (권장) ⭐

#### Step 1: Supabase SQL Editor 열기
```
Supabase 대시보드 → SQL Editor → New Query
```

#### Step 2: 다음 SQL 복사 & 실행

```sql
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Enable read access for all users" ON document_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON document_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON document_categories;

-- 새로운 정책 생성
CREATE POLICY "Enable read access for all users"
ON document_categories FOR SELECT
USING (is_active = true);

CREATE POLICY "Enable insert for authenticated users"
ON document_categories FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
ON document_categories FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
ON document_categories FOR DELETE
TO authenticated
USING (true);

-- RLS 활성화 확인
ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;
```

#### Step 3: "Run" 버튼 클릭
✅ Success 메시지 확인

#### Step 4: 웹 애플리케이션에서 다시 시도
카테고리 추가가 정상적으로 작동해야 합니다! 🎉

---

### 🎯 방법 2: RLS 임시 비활성화 (테스트용만)

⚠️ **주의**: 프로덕션 환경에서는 권장하지 않습니다!

```sql
-- RLS 비활성화
ALTER TABLE document_categories DISABLE ROW LEVEL SECURITY;
```

이렇게 하면 모든 사용자가 카테고리를 추가/수정/삭제할 수 있습니다.

---

## 📋 정책 설명

### 생성되는 4개 정책:

1. **읽기 (SELECT)** - 모든 사용자
   - 활성 카테고리(`is_active = true`)를 누구나 조회 가능

2. **추가 (INSERT)** - 인증된 사용자만
   - 로그인한 사용자만 새 카테고리 생성 가능

3. **수정 (UPDATE)** - 인증된 사용자만
   - 로그인한 사용자만 카테고리 정보 수정 가능

4. **삭제 (DELETE)** - 인증된 사용자만
   - 로그인한 사용자만 카테고리 삭제 가능

---

## 🔐 RLS란?

**Row Level Security (행 수준 보안)**
- PostgreSQL의 보안 기능
- 테이블의 각 행(row)에 대한 접근 권한을 세밀하게 제어
- 누가, 어떤 데이터를, 어떻게 접근할 수 있는지 정의

### Supabase의 역할 (Roles)

| 역할 | 설명 | 예시 |
|------|------|------|
| `anon` | 익명 사용자 | 로그인하지 않은 방문자 |
| `authenticated` | 인증된 사용자 | 로그인한 사용자 |
| `service_role` | 서비스 (관리자) | 백엔드 서버 |

웹 애플리케이션에서 Supabase를 사용하면 자동으로 `authenticated` 역할로 요청됩니다.

---

## 🧪 테스트 방법

### 1. 정책 확인
```sql
SELECT policyname, cmd, roles
FROM pg_policies 
WHERE tablename = 'document_categories';
```

**예상 결과**: 4개의 정책이 표시되어야 함

### 2. RLS 활성화 확인
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'document_categories';
```

**예상 결과**: `rowsecurity = true`

### 3. 카테고리 조회 테스트
```sql
SELECT * FROM document_categories 
WHERE is_active = true
ORDER BY display_order;
```

**예상 결과**: 기존 6개 카테고리 표시

---

## 📝 체크리스트

해결 후 다음을 확인하세요:

- [ ] SQL 스크립트 실행 완료 (Success 메시지 확인)
- [ ] 4개의 RLS 정책이 생성되었는지 확인
- [ ] RLS가 활성화되었는지 확인 (`rowsecurity = true`)
- [ ] 웹 애플리케이션에서 카테고리 추가 버튼 클릭
- [ ] "새 카테고리 추가" 폼에 정보 입력
- [ ] "저장" 버튼 클릭
- [ ] ✅ 성공 메시지 확인
- [ ] 카테고리 목록에 새 카테고리 표시 확인

---

## 🆘 여전히 오류가 발생하나요?

### 추가 확인 사항:

1. **Supabase 프로젝트 설정 확인**
   - Authentication이 활성화되어 있는가?
   - API 키가 올바른가?

2. **브라우저 콘솔 확인**
   - F12 → Console 탭
   - 빨간색 오류 메시지 확인

3. **Supabase 클라이언트 초기화 확인**
   ```javascript
   // index.html에서 확인
   this.sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
   ```

4. **네트워크 탭 확인**
   - F12 → Network 탭
   - Supabase API 요청 확인
   - 401 Unauthorized 오류 확인

---

## 📂 관련 파일

- **`database/FIX_CATEGORY_RLS_POLICY.sql`** - 상세 SQL 스크립트 (주석 포함)
- **`database/ONE_CLICK_SETUP.sql`** - 전체 데이터베이스 설정 (RLS 정책 포함)

---

## 🎉 해결 완료 후

정책이 정상적으로 설정되면:
1. ✅ 카테고리 추가 가능
2. ✅ 카테고리 수정 가능
3. ✅ 카테고리 삭제 가능
4. ✅ 모든 CRUD 기능 정상 작동

---

**문제가 해결되지 않으면 다음 정보를 알려주세요:**
1. Supabase SQL Editor에서 실행한 SQL 스크립트
2. 오류 메시지 (전체 텍스트)
3. 브라우저 콘솔의 오류 로그
4. Network 탭의 API 요청/응답

그러면 더 구체적으로 도와드리겠습니다! 🚀
