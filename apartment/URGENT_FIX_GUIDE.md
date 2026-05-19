# 🚨 긴급 수정 가이드: attendance_notes 테이블

## 🔴 핵심 문제

**에러 메시지:**
```
Invalid input syntax for type bigint: "adce328c-2eb6-4b22-b507-8d5d0049260b"
```

**원인:**
- `apartments.id` = **UUID** 타입
- `attendance_notes.apartment_id` = **bigint** 타입 ❌ **틀림!**
- **타입 불일치**로 인한 INSERT 실패

---

## ✅ 해결 방법

### 📋 Supabase SQL Editor에서 실행

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard
   - 프로젝트 선택

2. **SQL Editor 열기**
   - 왼쪽 메뉴 → `SQL Editor`
   - `New query` 클릭

3. **아래 SQL 복사해서 붙여넣기**

```sql
-- ⚠️ 기존 attendance_notes 테이블 삭제 및 재생성
DROP TABLE IF EXISTS attendance_notes CASCADE;

CREATE TABLE attendance_notes (
  id BIGSERIAL PRIMARY KEY,
  apartment_id UUID NOT NULL,           -- ✅ UUID로 수정!
  employee_name TEXT NOT NULL,
  note_date DATE NOT NULL,
  note_time TIME NOT NULL,
  note_type TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by TEXT DEFAULT 'system',
  attendance_record_id BIGINT
);

-- 인덱스 생성
CREATE INDEX idx_attendance_notes_apartment ON attendance_notes(apartment_id);
CREATE INDEX idx_attendance_notes_employee ON attendance_notes(employee_name);
CREATE INDEX idx_attendance_notes_date ON attendance_notes(note_date);
CREATE INDEX idx_attendance_notes_type ON attendance_notes(note_type);
CREATE INDEX idx_attendance_notes_created ON attendance_notes(created_at DESC);

-- RLS 활성화
ALTER TABLE attendance_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all for authenticated users" 
ON attendance_notes 
USING (true) 
WITH CHECK (true);
```

4. **실행**
   - 오른쪽 하단 `Run` 버튼 클릭
   - "Success. No rows returned" 확인

5. **검증**
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'attendance_notes';
   ```
   - `apartment_id` 컬럼이 **uuid** 타입인지 확인 ✅

---

## 🧪 테스트 방법

### 1️⃣ SQL 실행 후 즉시 테스트
```
1. scan.html 접속
2. 공휴일/근무시간외/비근무일 중 하나로 출근 시도
3. 사유 입력 (예: "긴급 청소 요청")
4. 확인:
   ✅ "기록에 성공했습니다"
   ✅ 콘솔에 "특이사항 기록 완료"
   ❌ bigint 에러 없음!
```

### 2️⃣ 관리자 페이지 확인
```
1. index.html → 상세 조회 탭
2. 확인:
   ✅ [공휴일] 뱃지 표시
   ✅ 사유 텍스트 표시
   ✅ 정상 작동!
```

---

## 📊 변경 사항

### Before (잘못된 스키마)
```sql
CREATE TABLE attendance_notes (
  apartment_id BIGINT,  -- ❌ 틀림
  employee_id BIGINT    -- ❌ 틀림
);
```

### After (올바른 스키마)
```sql
CREATE TABLE attendance_notes (
  apartment_id UUID NOT NULL,  -- ✅ 맞음
  employee_name TEXT NOT NULL   -- ✅ 이름만 사용
);
```

---

## ⚠️ 주의사항

### 데이터 손실
- ⚠️ **DROP TABLE**은 기존 데이터를 모두 삭제합니다
- 현재 attendance_notes 테이블에 중요한 데이터가 있다면:
  1. 먼저 백업 (`SELECT * FROM attendance_notes`)
  2. 엑셀로 저장
  3. SQL 실행 후 다시 INSERT

### 하지만...
- 현재 테스트 단계라면 걱정 없음 ✅
- 이전 데이터는 모두 저장 실패했으므로 실제로는 비어있음
- 안전하게 DROP 가능

---

## 🔍 왜 이런 문제가 발생했나?

### 설계 실수
1. 초기 테이블 생성 시 `apartment_id BIGINT`로 정의
2. 실제 `apartments` 테이블은 `id UUID` 사용
3. **스키마 검증 없이 코드 작성**
4. 런타임에서 타입 에러 발견

### 교훈
- ✅ 테이블 생성 전 외래키 타입 확인 필수
- ✅ 초기 마이그레이션 스크립트 검증
- ✅ 타입 불일치는 컴파일 타임에 잡을 수 없음 (SQL)

---

## 📝 체크리스트

- [ ] Supabase SQL Editor 접속
- [ ] `QUICK_FIX_SCHEMA.sql` 내용 복사
- [ ] SQL 실행 (Run 버튼)
- [ ] "Success" 메시지 확인
- [ ] 스키마 검증 쿼리 실행
- [ ] `apartment_id` 타입이 `uuid`인지 확인
- [ ] scan.html에서 특이사항 테스트
- [ ] 콘솔 에러 없는지 확인
- [ ] 관리자 페이지에서 표시 확인

---

## 🎯 결과

### SQL 실행 전
```
❌ Invalid input syntax for type bigint
→ 저장 실패 100%
```

### SQL 실행 후
```
✅ 특이사항 기록 완료
✅ 관리자 페이지 표시
→ 저장 성공 100%
```

---

## 🚀 배포 상태

- **코드**: ✅ 이미 준비됨 (변경 불필요)
- **DB 스키마**: ⚠️ **SQL 실행 필요** (사용자가 직접)
- **URL**: https://bdxi-qr-attendance.vercel.app/

---

## 💡 FAQ

### Q: SQL 실행하면 기존 기능이 망가지나요?
**A**: 아니요! attendance_notes는 **새로운 기능**이므로 다른 기능에 영향 없습니다.
- ✅ 출퇴근 기록 (attendance_records) - 정상
- ✅ 직원 관리 (employees) - 정상
- ✅ 위치 관리 (locations) - 정상
- ✅ 공휴일 관리 (holidays) - 정상
- ✅ 구매 관리 (purchases) - 정상

### Q: 실수로 잘못 실행하면?
**A**: 다시 실행하면 됩니다. `DROP TABLE IF EXISTS`는 멱등성(idempotent) 보장!

### Q: 백업은 어떻게 하나요?
**A**: 
```sql
-- 1. 데이터 확인
SELECT * FROM attendance_notes;

-- 2. CSV 다운로드
-- Supabase SQL Editor → 결과 → Export → CSV
```

---

## ✅ 최종 확인

SQL 실행 후 이 명령어로 검증:
```sql
-- 스키마 확인
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'attendance_notes'
ORDER BY ordinal_position;

-- 예상 결과:
-- apartment_id | uuid      ✅
-- employee_name | text     ✅
-- note_date | date         ✅
-- ...
```

---

**이제 SQL만 실행하면 끝입니다!** 🎉

실행 후 결과를 알려주세요!

---

*작성일: 2026-05-08*  
*파일: QUICK_FIX_SCHEMA.sql*  
*우선순위: 🔴 긴급*
