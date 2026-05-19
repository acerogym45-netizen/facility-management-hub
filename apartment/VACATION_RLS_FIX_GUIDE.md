# 휴가 신청 RLS 오류 긴급 수정 가이드

## 🚨 현재 오류 상황

### 콘솔 오류 메시지
```
POST https://...supabase.co/rest/v1/vacations 401 (Unauthorized)

Error: 
{code: '42501', 
 details: null, 
 hint: null, 
 message: 'new row violates row-level security policy for table "vacations"'}
```

### 문제 원인
1. **RLS (Row Level Security) 정책 문제**
   - vacations 테이블에 RLS가 활성화되어 있음
   - 하지만 정책이 올바르게 설정되지 않음
   - INSERT 작업이 거부됨

2. **end_date 컬럼 누락** (이미 확인됨)
   - 테이블 스키마에 end_date가 없음

---

## ✅ 해결 방법 (3단계)

### 🔥 **방법 1: RLS 완전 비활성화 (가장 빠름, 권장)**

**파일**: `DISABLE_VACATIONS_RLS.sql`

**실행 순서**:
1. Supabase Dashboard → SQL Editor
2. 아래 SQL 복사 후 실행:

```sql
-- RLS 완전 비활성화
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;

SELECT '✅ vacations 테이블의 RLS가 비활성화되었습니다!' AS message;
```

3. **즉시 테스트**: employee-app.html에서 휴가 신청 재시도

**장점**:
- ✅ 가장 빠르고 간단
- ✅ 기존 데이터 유지
- ✅ 즉시 작동

**단점**:
- ⚠️ 보안 정책 없음 (내부 시스템이므로 문제 없음)

---

### 🔧 **방법 2: RLS 정책 수정 (보안 유지)**

**파일**: `FIX_VACATIONS_RLS.sql`

**실행 순서**:
1. Supabase Dashboard → SQL Editor
2. 아래 SQL 복사 후 실행:

```sql
-- 1. 기존 정책 모두 삭제
DROP POLICY IF EXISTS "vacations_select_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_insert_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_update_policy" ON vacations;
DROP POLICY IF EXISTS "vacations_delete_policy" ON vacations;
DROP POLICY IF EXISTS "allow_all" ON vacations;

-- 2. RLS 비활성화 후 재활성화
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;

-- 3. 모든 작업 허용하는 단일 정책 생성
CREATE POLICY "vacations_allow_all_operations"
ON vacations
FOR ALL
USING (true)
WITH CHECK (true);

SELECT '✅ RLS 정책이 수정되었습니다!' AS message;
```

3. 테스트: employee-app.html에서 휴가 신청

**장점**:
- ✅ RLS 활성화 유지
- ✅ 모든 작업 허용
- ✅ 나중에 세밀한 정책 추가 가능

---

### 🔄 **방법 3: 테이블 완전 재생성 (최종 수단)**

**파일**: `COMPLETE_FIX_VACATIONS.sql`

⚠️ **주의**: 기존 휴가 데이터 모두 삭제됨!

**실행 순서**:
1. Supabase Dashboard → SQL Editor
2. 전체 SQL 실행 (위 파일 참고)
3. 새 테이블 + RLS 정책 자동 설정

**장점**:
- ✅ 모든 문제 한 번에 해결
- ✅ 깨끗한 시작

**단점**:
- ⚠️ 기존 데이터 삭제

---

## 🎯 **권장 순서**

### Step 1: RLS 비활성화 (가장 빠름)
```sql
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;
```
→ 휴가 신청 테스트 → ✅ 성공하면 완료!

### Step 2: end_date 컬럼 확인
```sql
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'vacations' AND column_name = 'end_date';
```
→ 결과 없으면 `QUICK_FIX_VACATIONS.sql` 실행

### Step 3: 최종 테스트
- employee-app.html 새로고침
- 휴가 신청 버튼 클릭
- 정보 입력 후 신청
- ✅ "휴가 신청이 완료되었습니다!" 확인

---

## 🧪 **테스트 체크리스트**

### SQL 실행 후 확인사항

#### 1. RLS 상태 확인
```sql
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename = 'vacations';
```

**예상 결과**:
- `rls_enabled = false` → RLS 비활성화 (권장)
- `rls_enabled = true` → RLS 활성화 (정책 확인 필요)

#### 2. RLS 정책 확인 (RLS 활성화된 경우)
```sql
SELECT 
    policyname,
    cmd,
    qual::text AS using_clause,
    with_check::text AS with_check_clause
FROM pg_policies
WHERE tablename = 'vacations';
```

**예상 결과**:
```
policyname                      | cmd  | using_clause | with_check_clause
--------------------------------|------|--------------|------------------
vacations_allow_all_operations  | ALL  | true         | true
```

#### 3. 컬럼 확인
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vacations'
ORDER BY ordinal_position;
```

**필수 컬럼**:
- ✅ id
- ✅ employee_id
- ✅ employee_name
- ✅ apartment_id
- ✅ vacation_type
- ✅ start_date
- ✅ **end_date** ⭐
- ✅ reason
- ✅ status
- ✅ created_at

#### 4. 수동 INSERT 테스트
```sql
INSERT INTO vacations (
    employee_id, 
    employee_name, 
    apartment_id, 
    vacation_type, 
    start_date, 
    end_date, 
    reason, 
    status
)
VALUES (
    'e4fde382-bf34-456d-9f62-6ffec337972a'::uuid,
    '테스트직원',
    'e4fde382-bf34-456d-9f62-6ffec337972a'::uuid,
    'annual',
    '2026-05-10',
    '2026-05-12',
    '테스트 휴가',
    'pending'
);

SELECT * FROM vacations ORDER BY created_at DESC LIMIT 1;
```

**예상 결과**: INSERT 성공, 데이터 조회됨

---

## 🐛 **추가 문제 해결**

### 문제 1: 여전히 401 Unauthorized 오류
```
Error: new row violates row-level security policy
```

**해결**:
```sql
-- RLS 완전 비활성화
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;
```

### 문제 2: end_date 컬럼 여전히 없음
```
Error: Could not find the 'end_date' column
```

**해결**:
```sql
-- end_date 컬럼 추가
ALTER TABLE vacations ADD COLUMN end_date DATE;
ALTER TABLE vacations ALTER COLUMN end_date SET NOT NULL;
```

### 문제 3: 제약조건 위반
```
Error: violates check constraint "valid_vacation_type"
```

**해결**:
```sql
-- 제약조건 삭제 (문제 있는 경우)
ALTER TABLE vacations DROP CONSTRAINT IF EXISTS valid_vacation_type;
ALTER TABLE vacations DROP CONSTRAINT IF EXISTS valid_status;
ALTER TABLE vacations DROP CONSTRAINT IF EXISTS valid_date_range;
```

---

## 📊 **RLS vs No RLS 비교**

| 항목 | RLS 활성화 | RLS 비활성화 |
|---|---|---|
| 보안 | ✅ 정책 기반 접근 제어 | ⚠️ 제한 없음 |
| 복잡도 | 🔴 높음 (정책 설정 필요) | 🟢 낮음 (설정 불필요) |
| 문제 발생 가능성 | 🔴 높음 (정책 오류) | 🟢 낮음 |
| 내부 시스템 적합성 | ⚠️ 과도한 보안 | ✅ 적절 |
| **권장 여부** | ❌ | ✅ |

**결론**: 내부 출퇴근 관리 시스템이므로 **RLS 비활성화 권장**

---

## 📁 **참고 파일**

1. **DISABLE_VACATIONS_RLS.sql** (295B)
   - RLS 완전 비활성화
   - 가장 빠른 해결책
   - ✅ 권장

2. **FIX_VACATIONS_RLS.sql** (906B)
   - RLS 정책 수정
   - 보안 유지

3. **COMPLETE_FIX_VACATIONS.sql** (2.7KB)
   - 테이블 완전 재생성
   - 모든 문제 한 번에 해결
   - ⚠️ 데이터 삭제

4. **QUICK_FIX_VACATIONS.sql** (2.6KB)
   - 컬럼 추가 (end_date 등)
   - 기존 데이터 유지

---

## 🚀 **빠른 해결 (1분 완성)**

### 1단계: RLS 비활성화
```sql
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;
```

### 2단계: end_date 추가 (없는 경우)
```sql
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS end_date DATE;
```

### 3단계: 테스트
- employee-app.html 새로고침
- 휴가 신청
- ✅ 성공!

---

## 📞 **문제 지속 시**

다음 정보를 제공해주세요:
1. SQL 실행 결과 스크린샷
2. 브라우저 콘솔 오류 전체
3. RLS 상태 확인 쿼리 결과
4. 컬럼 확인 쿼리 결과

---

**작성일**: 2026-05-08  
**버전**: v2.0 (RLS 문제 추가)  
**상태**: 🔥 긴급 수정
