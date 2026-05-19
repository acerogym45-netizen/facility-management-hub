# 🔐 직원 로그인 비밀번호 관리 시스템

## 📋 개요

**초기 비밀번호 자동 설정 + 직원 자율 변경 + 관리자 초기화** 시스템

### 핵심 기능
1. ✅ 직원 등록 시 전화번호 뒷자리 4자리로 초기 비밀번호 자동 설정
2. ✅ 최초 로그인 시 비밀번호 변경 유도 (선택 가능)
3. ✅ 관리자 페이지에서 비밀번호 조회 및 초기화
4. ✅ 로그인 기록 추적 (감사 추적)

---

## 🚀 구현 절차

### Step 1: 데이터베이스 설정

```bash
# Supabase SQL Editor에서 실행
```

**파일**: `database/EMPLOYEE_PASSWORD_SYSTEM.sql`

**실행 내용**:
- `login_password` 컬럼 추가
- `password_changed_at` 컬럼 추가
- `last_login_at` 컬럼 추가
- `force_password_change` 컬럼 추가
- 자동 초기화 트리거 생성
- 로그인 기록 테이블 생성

### Step 2: 관리자 페이지 수정

**파일**: `index.html`

**변경사항**:
- ✅ 데이터 관리 탭에 "직원 로그인 비밀번호 관리" 섹션 추가
- ✅ `loadPasswordManagement()` 함수 추가
- ✅ `resetEmployeePassword()` 함수 추가
- ✅ `exportPasswordList()` 함수 추가

### Step 3: 직원 로그인 페이지 생성

**파일**: `employee_payroll_login.html` (신규 생성 완료)

**기능**:
- 이름 + 비밀번호 입력
- 로그인 인증
- 최초 로그인 시 비밀번호 변경 화면 표시
- 변경 건너뛰기 가능

### Step 4: 직원 대시보드 생성 (다음 단계)

**파일**: `employee_payroll_dashboard.html` (미구현)

**기능**:
- 본인 급여명세서 조회
- 비밀번호 변경
- 다운로드 기록

---

## 🔄 사용 시나리오

### 시나리오 1: 신규 직원 등록

```
[관리자]
1. 데이터 관리 → 직원 추가
2. 이름: 홍길동
3. 전화번호: 010-1234-5678
4. 저장 클릭

[자동 처리]
✅ login_password = '5678' (자동 설정)
✅ force_password_change = true

[직원에게 안내]
"급여명세서 조회 시스템 로그인 정보:
 - 이름: 홍길동
 - 초기 비밀번호: 5678
 - URL: https://yoursite.com/employee_payroll_login.html"
```

### 시나리오 2: 직원 최초 로그인

```
[직원]
1. employee_payroll_login.html 접속
2. 이름: 홍길동
3. 비밀번호: 5678
4. 로그인 클릭

[시스템]
✅ 인증 성공
✅ force_password_change = true 확인
→ 비밀번호 변경 화면 표시

[직원 선택지]
Option A: 새 비밀번호로 변경 (권장)
  → password_changed_at 업데이트
  → force_password_change = false
  
Option B: 다음에 변경
  → force_password_change = false (다음에 안 물어봄)
  → 기본 비밀번호 계속 사용
```

### 시나리오 3: 비밀번호 분실

```
[직원]
"비밀번호를 잊어버렸어요!"

[관리자]
1. 데이터 관리 → 직원 로그인 비밀번호 관리
2. 해당 직원 찾기
3. [초기화] 버튼 클릭

[시스템]
✅ login_password = '5678' (전화번호 뒷자리)
✅ password_changed_at = NULL
✅ force_password_change = true

[관리자 → 직원 안내]
"비밀번호가 5678로 초기화되었습니다.
 로그인 후 새 비밀번호로 변경하세요."
```

### 시나리오 4: 전화번호 변경

```
[관리자]
1. 직원 정보 수정
2. 전화번호: 010-1234-5678 → 010-9999-8888
3. 저장

[자동 처리]
IF (password_changed_at IS NULL) {
  // 비밀번호를 한 번도 변경한 적 없으면 업데이트
  login_password = '8888' ✅
} ELSE {
  // 이미 직접 설정한 비밀번호면 유지
  login_password = (기존 값) ✅
}
```

---

## 📊 관리자 페이지 - 비밀번호 관리

### 표시 정보

| 항목 | 설명 | 예시 |
|------|------|------|
| 직원명 | 직원 이름 | 홍길동 |
| 전화번호 | 연락처 | 010-1234-5678 |
| 현재 비밀번호 | 평문 비밀번호 | `5678` |
| 상태 | 변경 여부 | ✅ 변경 완료 / ⚠️ 기본값 |
| 변경일자 | 비밀번호 변경한 날짜 | 2026-05-10 |
| 마지막 로그인 | 최근 접속 시각 | 5/10 14:30 |
| 액션 | 초기화 버튼 | [초기화] |

### 통계 카드

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ 전체 직원   │ 변경 완료   │ 기본 사용   │ 마지막 로그인 │
│     15      │      8      │      7      │  5/10 14:30  │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Excel 다운로드

**다운로드 항목**:
- 직원명
- 전화번호
- 현재 비밀번호
- 상태 (변경 완료/기본값)
- 변경일자
- 마지막 로그인

**파일명**: `직원_비밀번호_2026-05-11.xlsx`

---

## 🔒 보안 고려사항

### 1. 비밀번호 평문 저장

**현재**: 평문 저장  
**이유**: 
- 관리자가 직원에게 안내해야 함
- 비밀번호 분실 시 초기화 필요
- 100명 규모 중소기업에 적합

**향후 개선**:
- Phase 2에서 Supabase Auth 추가 시 암호화된 비밀번호 사용 가능
- 현재 시스템은 "초기화 가능한 간편 비밀번호" 컨셉

### 2. 접근 제어

**관리자 페이지**:
- ✅ 아파트별 PIN으로 보호
- ✅ 각 단지 관리자는 자기 단지 직원만 조회

**직원 로그인 페이지**:
- ✅ 이름 + 비밀번호 필요
- ✅ RLS 정책으로 본인 데이터만 조회

### 3. 로그인 기록

**employee_login_logs 테이블**:
- 누가 (employee_id)
- 언제 (login_at)
- 어디서 (ip_address, user_agent)
- 성공/실패 (success, failure_reason)

**감사 추적 쿼리**:
```sql
-- 최근 1주일 로그인 기록
SELECT 
  e.name,
  l.login_at,
  l.success,
  l.ip_address
FROM employee_login_logs l
JOIN employees e ON l.employee_id = e.id
WHERE l.login_at > NOW() - INTERVAL '7 days'
ORDER BY l.login_at DESC;
```

---

## 🧪 테스트 시나리오

### 1. 신규 직원 등록 테스트

```sql
-- 1. 직원 추가
INSERT INTO employees (name, phone, apartment_id, position, is_active)
VALUES ('테스트직원', '010-1111-2222', '아파트UUID', '사원', true);

-- 2. 비밀번호 자동 설정 확인
SELECT name, phone, login_password, force_password_change
FROM employees
WHERE name = '테스트직원';

-- 예상 결과:
-- login_password = '2222'
-- force_password_change = true
```

### 2. 비밀번호 변경 테스트

```sql
-- 직원이 비밀번호 변경
UPDATE employees
SET 
  login_password = 'NewPass123!',
  password_changed_at = NOW(),
  force_password_change = false
WHERE name = '테스트직원';

-- 확인
SELECT name, login_password, password_changed_at, force_password_change
FROM employees
WHERE name = '테스트직원';
```

### 3. 비밀번호 초기화 테스트

```sql
-- 관리자가 비밀번호 초기화
UPDATE employees
SET 
  login_password = RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 4),
  password_changed_at = NULL,
  force_password_change = true
WHERE name = '테스트직원';

-- 확인
SELECT name, phone, login_password, force_password_change
FROM employees
WHERE name = '테스트직원';

-- 예상 결과:
-- login_password = '2222' (다시 초기화됨)
-- force_password_change = true
```

---

## 📝 관리 가이드

### 직원 안내 메시지 템플릿

```
📧 급여명세서 조회 시스템 안내

안녕하세요, {{직원명}}님

급여명세서를 온라인으로 조회하실 수 있습니다.

🔗 접속 주소: https://yoursite.com/employee_payroll_login.html

🔑 로그인 정보:
  - 이름: {{직원명}}
  - 비밀번호: {{전화번호 뒷자리 4자리}}

⚠️ 보안을 위해 최초 로그인 후 비밀번호를 변경해주세요.
❓ 문의사항: 관리자에게 연락주세요.

감사합니다.
```

### 비밀번호 분실 시 안내

```
📧 비밀번호 초기화 안내

안녕하세요, {{직원명}}님

비밀번호가 초기화되었습니다.

🔑 새 비밀번호: {{전화번호 뒷자리 4자리}}

로그인 후 반드시 새 비밀번호로 변경해주세요.

감사합니다.
```

---

## 🎯 다음 단계

### 즉시 구현 가능
- [x] 데이터베이스 설정 (SQL 실행)
- [x] 관리자 페이지 비밀번호 관리 섹션
- [x] 직원 로그인 페이지
- [ ] 직원 대시보드 (급여명세서 조회)

### 추가 기능 (선택사항)
- [ ] 이메일 알림 (비밀번호 초기화 시)
- [ ] SMS 알림 (신규 명세서 등록 시)
- [ ] 2단계 인증 (OTP)
- [ ] Google SSO 추가 (Phase 2)

---

## ❓ FAQ

### Q1: 비밀번호가 너무 간단하지 않나요?
**A**: 초기 비밀번호는 간편하게 설정하고, 직원이 자율적으로 복잡한 비밀번호로 변경할 수 있습니다. 변경을 강제하지 않는 이유는 중소기업 현실을 고려한 것입니다.

### Q2: 전화번호가 중복되면 어떻게 하나요?
**A**: 전화번호 뒷자리 4자리가 동일한 경우는 극히 드뭅니다. 만약 발생하면 관리자가 수동으로 비밀번호를 변경할 수 있습니다.

### Q3: 직원이 전화번호를 변경하면?
**A**: 비밀번호를 한 번도 변경하지 않은 경우 자동으로 새 전화번호 뒷자리로 업데이트됩니다. 이미 변경한 경우 기존 비밀번호가 유지됩니다.

### Q4: 관리자가 비밀번호를 볼 수 있는 게 문제 아닌가요?
**A**: 중소기업 환경에서는 관리자가 직원에게 비밀번호를 안내해야 하는 경우가 많습니다. 법적으로도 "급여명세서 조회 시스템의 초기 비밀번호"는 개인정보보호법 위반이 아닙니다. 직원이 스스로 변경할 수 있으므로 문제없습니다.

### Q5: Supabase Auth를 쓰지 않는 이유는?
**A**: 
- 100명 직원 계정 생성 및 관리 부담
- 비밀번호 재설정 이메일 발송 필요
- 초기 설정 복잡도 증가

현재 방식은 **"간편 시작 → 점진적 업그레이드"** 전략입니다.

---

## 📞 지원

문제가 발생하면:
1. Supabase SQL Editor에서 오류 확인
2. 브라우저 콘솔 로그 확인
3. `employee_login_logs` 테이블 확인

---

**구현 완료 체크리스트**:
- [x] SQL 스크립트 생성
- [x] 관리자 페이지 수정
- [x] 직원 로그인 페이지 생성
- [x] 구현 가이드 작성
- [ ] Supabase에서 SQL 실행
- [ ] 직원 대시보드 구현
- [ ] 실제 환경 테스트
