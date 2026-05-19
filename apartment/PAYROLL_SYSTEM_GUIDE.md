# 급여명세서 자동 배포 시스템 구현 가이드 🚀

## 📋 목차
1. [시스템 개요](#시스템-개요)
2. [데이터베이스 구조](#데이터베이스-구조)
3. [구현 단계](#구현-단계)
4. [사용자 역할](#사용자-역할)
5. [워크플로우](#워크플로우)
6. [UI 화면 목록](#ui-화면-목록)

---

## 시스템 개요

### 🎯 목표
**하이브리드 급여명세서 배포 시스템**: 디지털 우선 + 오프라인 보완

### 💡 핵심 기능
```
1차: 직원 개인 계정 로그인 → 자동 다운로드
2차: 미수령자 → 단지 관리자가 오프라인 전달
```

### ✅ 장점
- ✅ 개인정보 보호 (본인만 조회)
- ✅ 100% 전달 보장 (디지털 + 오프라인)
- ✅ 법적 안전성 확보
- ✅ 업무 효율화 (자동 알림)

---

## 데이터베이스 구조

### 📊 테이블 관계도
```
employees (기존)
  ↓ (1:N)
payroll_statements (급여명세서)
  ↓ (1:N)
payroll_notifications (알림 로그)
```

### 🗂️ 주요 테이블

#### 1. `employees` (직원 - 확장)
```sql
-- 기존 컬럼
id, name, employee_number, department, position, phone, is_active

-- 추가 컬럼
email               -- 로그인 이메일
auth_user_id        -- Supabase Auth 연동
role                -- employee/manager/admin
apartment_id        -- 소속 단지
last_login_at       -- 마지막 로그인
is_verified         -- 이메일 인증 여부
```

#### 2. `payroll_statements` (급여명세서)
```sql
id                    -- UUID
employee_id           -- 직원 ID
year_month            -- '2026-05'
file_url              -- Storage URL
file_name             -- 파일명
pdf_password          -- PDF 암호 (선택)

status                -- pending/viewed/downloaded/printed
uploaded_by           -- 업로드한 관리자
uploaded_at           -- 업로드 시간

first_viewed_at       -- 최초 조회
last_viewed_at        -- 마지막 조회
view_count            -- 조회 횟수
download_count        -- 다운로드 횟수

email_sent_at         -- 이메일 발송 시간
sms_sent_at           -- SMS 발송 시간

offline_delivered     -- 오프라인 전달 여부
offline_delivered_by  -- 전달한 관리자
offline_delivered_at  -- 전달 시간
```

#### 3. `payroll_notifications` (알림 로그)
```sql
id                    -- UUID
payroll_statement_id  -- 명세서 ID
employee_id           -- 직원 ID
notification_type     -- email/sms/push
recipient             -- 수신자
status                -- pending/sent/failed/opened
```

---

## 구현 단계

### 📅 Phase 1: 데이터베이스 설정 (1일)

#### Step 1: SQL 실행
```bash
Supabase SQL Editor → CREATE_PAYROLL_SYSTEM.sql 실행
```

#### Step 2: 기존 직원 이메일 추가
```sql
-- 실제 이메일 주소로 업데이트
UPDATE employees 
SET email = '직원이메일@example.com',
    role = 'employee'
WHERE employee_number = 'EMP001';

-- 본사 관리자 설정
UPDATE employees 
SET email = 'admin@masterplan.com',
    role = 'admin'
WHERE employee_number = 'MASTER001';

-- 단지 관리자 설정
UPDATE employees 
SET email = 'manager@masterplan.com',
    role = 'manager',
    apartment_id = (SELECT id FROM apartments WHERE name = '단지명' LIMIT 1)
WHERE employee_number = 'MGR001';
```

#### Step 3: Supabase Auth 계정 생성
```javascript
// Supabase Dashboard → Authentication → Users → Invite User
// 또는 API로 일괄 생성
const { data, error } = await supabase.auth.admin.createUser({
  email: 'employee@example.com',
  password: '임시비밀번호',
  email_confirm: true
});

// employees 테이블에 auth_user_id 연결
await supabase
  .from('employees')
  .update({ auth_user_id: data.user.id })
  .eq('email', 'employee@example.com');
```

---

### 📅 Phase 2: Storage 설정 (30분)

```sql
-- Storage 버킷 생성
INSERT INTO storage.buckets (id, name, public)
VALUES ('payroll-statements', 'payroll-statements', false); -- private!

-- RLS 정책: 본인 파일만 읽기
CREATE POLICY "Employees can view own payroll files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'payroll-statements' AND
  name LIKE auth.uid() || '/%'
);

-- 본사 관리자: 모든 파일 관리
CREATE POLICY "Admins can manage all payroll files"
ON storage.objects FOR ALL
USING (
  bucket_id = 'payroll-statements' AND
  EXISTS (
    SELECT 1 FROM employees WHERE auth_user_id = auth.uid() AND role = 'admin'
  )
);
```

---

### 📅 Phase 3: UI 구현 (3-4일)

#### 화면 목록
1. ✅ **직원 로그인 페이지** (`employee_login.html`)
2. ✅ **직원 대시보드** (`employee_dashboard.html`)
3. ✅ **급여명세서 조회** (`payroll_view.html`)
4. ✅ **본사 업로드 페이지** (`admin_payroll_upload.html`)
5. ✅ **배포 현황 대시보드** (`admin_payroll_dashboard.html`)
6. ✅ **단지 관리자 현황** (`manager_payroll_status.html`)

---

## 사용자 역할

### 👤 직원 (employee)
**권한:**
- ✅ 본인 급여명세서 조회
- ✅ PDF 다운로드
- ✅ 과거 명세서 조회 (6개월~3년)

**화면:**
- 로그인 → 대시보드 → 급여명세서 목록 → PDF 다운로드

---

### 👔 단지 관리자 (manager)
**권한:**
- ✅ 소속 단지 직원 배포 현황 조회
- ✅ 미수령자 목록 확인
- ✅ 오프라인 전달 완료 체크

**화면:**
- 로그인 → 관리자 대시보드 → 배포 현황 → 미수령자 처리

---

### 👨‍💼 본사 관리자 (admin)
**권한:**
- ✅ 급여명세서 일괄 업로드
- ✅ 전체 배포 현황 조회
- ✅ 미수령자 알림 재발송
- ✅ 직원 계정 관리

**화면:**
- 로그인 → 관리자 대시보드 → 업로드 → 현황 모니터링

---

## 워크플로우

### 📤 1. 업로드 프로세스 (본사)

```
1. 본사 인사팀 → 급여 계산 완료
2. 급여명세서 PDF 생성 (직원별)
3. 파일명 규칙: {사번}_{년월}.pdf
   예: EMP001_2026-05.pdf
4. admin_payroll_upload.html 접속
5. 파일 드래그 앤 드롭 또는 선택
6. 자동 매칭: 파일명에서 사번 추출 → employees 테이블 매칭
7. Supabase Storage 업로드
8. payroll_statements 테이블에 메타데이터 저장
9. 자동 이메일 발송 (모든 직원)
```

### 📥 2. 수령 프로세스 (직원 - 1차)

```
1. 이메일 수신: "급여명세서가 도착했습니다"
2. 링크 클릭 → employee_login.html
3. 로그인 (이메일 + 비밀번호)
4. employee_dashboard.html → 새 명세서 알림
5. 급여명세서 조회 → PDF 다운로드
6. 상태 자동 업데이트: pending → viewed → downloaded
```

### 📋 3. 오프라인 배포 (단지 관리자 - 2차)

```
[7일 후]
1. 시스템 자동 체크: 미수령자 목록 생성
2. 단지 관리자에게 알림 발송
3. manager_payroll_status.html 접속
4. 미수령자 목록 확인
5. 인쇄 또는 이메일 재발송
6. 오프라인 전달 완료 체크
7. 전달 확인 메모 작성
```

---

## UI 화면 목록

### 1️⃣ 직원 로그인 (`employee_login.html`)

**기능:**
- 이메일 + 비밀번호 로그인
- "비밀번호 찾기" 링크
- Supabase Auth 연동

**화면 구성:**
```html
- 로고
- 이메일 입력
- 비밀번호 입력
- 로그인 버튼
- 비밀번호 찾기 링크
```

---

### 2️⃣ 직원 대시보드 (`employee_dashboard.html`)

**기능:**
- 최신 급여명세서 알림
- 급여명세서 목록 (최근 6개월)
- 다운로드 버튼
- 과거 명세서 조회

**화면 구성:**
```html
- 헤더: 직원 이름, 로그아웃
- 알림: "새로운 급여명세서가 도착했습니다"
- 카드: 최신 명세서 (2026년 5월)
  - 다운로드 버튼
  - 조회 시간
- 과거 명세서 목록
```

---

### 3️⃣ 본사 업로드 (`admin_payroll_upload.html`)

**기능:**
- 파일 일괄 업로드 (드래그 앤 드롭)
- 자동 사번 매칭
- 업로드 진행률 표시
- 에러 처리 (매칭 실패 시)

**화면 구성:**
```html
- 드래그 앤 드롭 영역
- 파일 선택 버튼
- 업로드 진행률 바
- 매칭 결과 테이블
  - 파일명 | 직원명 | 상태
- 이메일 발송 버튼
```

---

### 4️⃣ 배포 현황 대시보드 (`admin_payroll_dashboard.html`)

**기능:**
- 월별 배포 현황 조회
- 수령률 차트
- 미수령자 목록
- 알림 재발송

**화면 구성:**
```html
- 통계 카드 (4개)
  - 총 발송: 95명
  - 수령 완료: 78명
  - 미수령: 17명
  - 수령률: 82%
- 차트: 수령 현황
- 미수령자 테이블
  - 직원명 | 부서 | 단지 | 업로드일 | 경과일 | 액션
```

---

### 5️⃣ 단지 관리자 현황 (`manager_payroll_status.html`)

**기능:**
- 소속 단지 직원 배포 현황
- 미수령자 확인
- 오프라인 전달 완료 체크

**화면 구성:**
```html
- 단지 통계
  - 소속 직원: 20명
  - 수령 완료: 15명
  - 미수령: 5명
- 미수령자 목록
  - 직원명 | 부서 | 연락처 | 경과일
  - [오프라인 전달 완료] 버튼
- 전달 메모 입력
```

---

## 🔐 보안 정책

### RLS (Row Level Security)
```sql
-- 직원: 본인 명세서만 조회
CREATE POLICY "own_payroll" ON payroll_statements
USING (employee_id IN (
  SELECT id FROM employees WHERE auth_user_id = auth.uid()
));

-- 단지 관리자: 소속 단지만
CREATE POLICY "manager_apartment" ON payroll_statements
USING (employee_id IN (
  SELECT id FROM employees WHERE apartment_id IN (
    SELECT apartment_id FROM employees 
    WHERE auth_user_id = auth.uid() AND role = 'manager'
  )
));

-- 본사: 모든 데이터
CREATE POLICY "admin_all" ON payroll_statements
USING (
  EXISTS (
    SELECT 1 FROM employees 
    WHERE auth_user_id = auth.uid() AND role = 'admin'
  )
);
```

---

## 📧 이메일 알림 템플릿

### 신규 명세서 알림
```
제목: [마스터플랜리소스] 2026년 5월 급여명세서가 도착했습니다

안녕하세요, {직원명}님

2026년 5월 급여명세서가 업로드되었습니다.
아래 링크를 클릭하여 확인하세요.

[급여명세서 확인하기]

* 로그인 정보
  - 이메일: {이메일}
  - 비밀번호: 가입 시 설정한 비밀번호

문의사항: master@masterplan.com
```

---

## 🚀 다음 단계

### 즉시 시작
1. ✅ `CREATE_PAYROLL_SYSTEM.sql` 실행
2. ✅ 직원 이메일 추가
3. ✅ Supabase Auth 계정 생성

### UI 구현 순서
1. 직원 로그인 페이지
2. 직원 대시보드
3. 본사 업로드 페이지
4. 배포 현황 대시보드
5. 단지 관리자 페이지

어느 화면부터 구현할까요? 🎨
