# 휴가 신청 오류 해결 가이드

## 🚨 오류 내용
```
휴가 신청 실패: Could not find the 'end_date' column of 'vacations' in the schema cache
```

## 🔍 원인
`vacations` 테이블에 `end_date` 컬럼이 없거나 스키마 구조가 올바르지 않습니다.

---

## ✅ 해결 방법

### 방법 1: 완전 재생성 (권장)
기존 데이터가 없거나 중요하지 않은 경우 사용

**실행 파일**: `FIX_VACATIONS_TABLE.sql`

**순서**:
1. Supabase Dashboard → SQL Editor 접속
2. `FIX_VACATIONS_TABLE.sql` 파일 내용 복사
3. SQL Editor에 붙여넣기
4. **Run** 버튼 클릭

**특징**:
- ✅ 완전히 새로운 테이블 생성
- ✅ 모든 필요한 컬럼 포함
- ✅ 인덱스 및 제약조건 설정
- ✅ RLS 정책 설정
- ⚠️ 기존 데이터 삭제됨

---

### 방법 2: 기존 테이블 수정 (안전)
기존 데이터를 유지하고 싶은 경우 사용

**실행 파일**: `QUICK_FIX_VACATIONS.sql`

**순서**:
1. Supabase Dashboard → SQL Editor 접속
2. `QUICK_FIX_VACATIONS.sql` 파일 내용 복사
3. SQL Editor에 붙여넣기
4. **Run** 버튼 클릭

**특징**:
- ✅ 기존 데이터 유지
- ✅ 누락된 컬럼만 추가
- ✅ 제약조건 및 인덱스 추가
- ✅ 안전한 업데이트

---

## 📋 테이블 구조

### vacations 테이블 스키마
```sql
CREATE TABLE vacations (
    -- 기본 정보
    id BIGSERIAL PRIMARY KEY,
    
    -- 직원 정보
    employee_id UUID NOT NULL,           -- 직원 UUID
    employee_name TEXT NOT NULL,         -- 직원 이름
    
    -- 단지 정보
    apartment_id UUID NOT NULL,          -- 단지 UUID
    
    -- 휴가 정보
    vacation_type TEXT NOT NULL,         -- 휴가 종류 (annual/half_day/sick/personal/other)
    start_date DATE NOT NULL,            -- 시작일 ⭐
    end_date DATE NOT NULL,              -- 종료일 ⭐ (없어서 오류 발생)
    reason TEXT NOT NULL,                -- 사유
    
    -- 상태 정보
    status TEXT DEFAULT 'pending',       -- 상태 (pending/approved/rejected)
    admin_comment TEXT,                  -- 관리자 코멘트
    approved_by TEXT,                    -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,-- 승인 일시
    
    -- 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 필수 컬럼
- ✅ `id` - 기본 키
- ✅ `employee_id` - 직원 UUID
- ✅ `employee_name` - 직원 이름
- ✅ `apartment_id` - 단지 UUID
- ✅ `vacation_type` - 휴가 종류
- ✅ `start_date` - 시작일
- ✅ `end_date` - 종료일 ⭐ **이것이 없어서 오류 발생**
- ✅ `reason` - 사유
- ✅ `status` - 상태

---

## 🧪 테스트

### 1. 스키마 확인
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'vacations'
ORDER BY ordinal_position;
```

**예상 결과**:
```
column_name     | data_type                   | is_nullable
----------------|-----------------------------|-----------
id              | bigint                      | NO
employee_id     | uuid                        | NO
employee_name   | text                        | NO
apartment_id    | uuid                        | NO
vacation_type   | text                        | NO
start_date      | date                        | NO
end_date        | date                        | NO         ⭐ 이 컬럼이 있어야 함
reason          | text                        | NO
status          | text                        | NO
admin_comment   | text                        | YES
approved_by     | text                        | YES
approved_at     | timestamp with time zone    | YES
created_at      | timestamp with time zone    | YES
updated_at      | timestamp with time zone    | YES
```

### 2. 휴가 신청 테스트
employee-app.html에서:
1. 휴가 신청 버튼 클릭
2. 종류: 연차 선택
3. 시작일: 2026-05-10
4. 종료일: 2026-05-12
5. 사유: "테스트 휴가"
6. 신청 버튼 클릭

**예상 결과**: ✅ "휴가 신청이 완료되었습니다!" 메시지

### 3. DB 확인
```sql
SELECT * FROM vacations ORDER BY created_at DESC LIMIT 5;
```

---

## 🔧 추가 수정 사항

### RLS (Row Level Security) 정책
테이블에 접근 권한이 없는 경우:

```sql
-- RLS 활성화
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;

-- 조회 정책
CREATE POLICY "vacations_select_policy" ON vacations
    FOR SELECT USING (true);

-- 삽입 정책
CREATE POLICY "vacations_insert_policy" ON vacations
    FOR INSERT WITH CHECK (true);

-- 업데이트 정책
CREATE POLICY "vacations_update_policy" ON vacations
    FOR UPDATE USING (true) WITH CHECK (true);
```

### 인덱스 추가
성능 향상을 위한 인덱스:

```sql
CREATE INDEX idx_vacations_employee ON vacations(employee_id);
CREATE INDEX idx_vacations_apartment ON vacations(apartment_id);
CREATE INDEX idx_vacations_status ON vacations(status);
CREATE INDEX idx_vacations_dates ON vacations(start_date, end_date);
```

---

## 📝 체크리스트

### SQL 실행 전
- [ ] Supabase Dashboard 로그인
- [ ] SQL Editor 접속
- [ ] 기존 데이터 백업 (필요한 경우)
- [ ] SQL 파일 선택 (완전 재생성 또는 수정)

### SQL 실행
- [ ] SQL 복사 → 붙여넣기
- [ ] Run 버튼 클릭
- [ ] 실행 결과 확인
- [ ] "✅ 성공" 메시지 확인

### 실행 후
- [ ] 스키마 확인 쿼리 실행
- [ ] `end_date` 컬럼 존재 확인
- [ ] employee-app.html에서 휴가 신청 테스트
- [ ] 성공 메시지 확인
- [ ] DB에 데이터 저장 확인

---

## 🐛 추가 문제 해결

### 문제 1: RLS 권한 오류
```
new row violates row-level security policy
```

**해결**:
```sql
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all" ON vacations FOR ALL USING (true);
```

### 문제 2: 제약조건 위반
```
violates check constraint "valid_vacation_type"
```

**해결**:
`vacation_type`이 올바른 값인지 확인:
- annual
- half_day
- sick
- personal
- other

### 문제 3: NULL 값 오류
```
null value in column "end_date" violates not-null constraint
```

**해결**:
시작일과 종료일이 모두 선택되었는지 확인

---

## 📞 지원

### 파일 위치
- `/home/user/webapp/FIX_VACATIONS_TABLE.sql` - 완전 재생성 스크립트
- `/home/user/webapp/QUICK_FIX_VACATIONS.sql` - 기존 테이블 수정 스크립트
- `/home/user/webapp/CHECK_VACATIONS_SCHEMA.sql` - 스키마 확인 스크립트

### 추가 도움
문제가 계속되면 다음 정보를 제공해주세요:
1. Supabase SQL Editor 실행 결과 스크린샷
2. 브라우저 콘솔 오류 메시지
3. 스키마 확인 쿼리 결과

---

**작성일**: 2026-05-08  
**버전**: v1.0  
**상태**: 🔧 수정 필요
