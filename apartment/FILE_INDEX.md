# 📚 프로젝트 문서 인덱스

**카인드원 관리시스템 - 직원 로그인 비밀번호 & 급여명세서 배포 시스템**

이 문서는 프로젝트의 모든 파일과 문서를 한눈에 볼 수 있도록 정리한 인덱스입니다.

---

## 🎯 시작하기 (처음 보시는 분)

**가장 먼저 읽어야 할 문서**:

1. **QUICK_START.md** ⭐⭐⭐ - 3단계 빠른 배포 가이드 (5분 소요)
2. **PROJECT_STATUS_SUMMARY.md** - 전체 프로젝트 상태 요약

---

## 📖 가이드 문서

### 배포 및 구현 가이드

| 문서 | 목적 | 대상 |
|------|------|------|
| **QUICK_START.md** | 3단계 빠른 배포 (5분) | 처음 배포하는 관리자 |
| **PAYROLL_IMPLEMENTATION_GUIDE.md** | A→D→B→C 상세 실행 가이드 | 개발자/시스템 관리자 |
| **PROJECT_STATUS_SUMMARY.md** | 프로젝트 전체 요약 | 모든 사용자 |

### 시스템별 상세 가이드

| 문서 | 목적 | 내용 |
|------|------|------|
| **EMPLOYEE_PASSWORD_GUIDE.md** | 비밀번호 시스템 사용법 | 자동 설정, 초기화, 관리 방법 |
| **PAYROLL_SYSTEM_GUIDE.md** | 급여 시스템 개요 | 워크플로우, 법적 준수 사항 |

---

## 💾 데이터베이스 스크립트

### 필수 실행 스크립트 (반드시 실행해야 함)

| 파일 | 단계 | 크기 | 설명 |
|------|------|------|------|
| **database/EMPLOYEE_PASSWORD_SYSTEM.sql** | Step A | 7.0KB (195줄) | 직원 비밀번호 관리 시스템 |
| **database/CREATE_PAYROLL_SYSTEM.sql** | Step D | 13KB (360줄) | 급여명세서 배포 시스템 |

**실행 방법**: Supabase SQL Editor에서 위 파일들을 순서대로 실행

---

## 🌐 웹 페이지

### 직원용 페이지

| 파일 | 용도 | URL 패턴 |
|------|------|----------|
| **employee_payroll_login.html** | 로그인 + 비밀번호 변경 | `/employee_payroll_login.html` |
| **employee_payroll_dashboard.html** | 급여명세서 조회 | `/employee_payroll_dashboard.html` |

### 관리자 페이지

| 파일 | 용도 | 주요 기능 |
|------|------|----------|
| **index.html** | 메인 관리 시스템 | 데이터 관리 탭 → 🔐 직원 로그인 비밀번호 관리 |

---

## 🗂️ 파일 구조

```
webapp/
├── 📘 가이드 문서 (먼저 읽으세요!)
│   ├── QUICK_START.md                      ⭐ 3단계 빠른 시작
│   ├── PROJECT_STATUS_SUMMARY.md           프로젝트 전체 요약
│   ├── PAYROLL_IMPLEMENTATION_GUIDE.md     A→D→B→C 실행 가이드
│   ├── EMPLOYEE_PASSWORD_GUIDE.md          비밀번호 시스템 가이드
│   └── PAYROLL_SYSTEM_GUIDE.md             급여 시스템 개요
│
├── 💾 데이터베이스 스크립트
│   └── database/
│       ├── EMPLOYEE_PASSWORD_SYSTEM.sql    ✅ Step A (반드시 실행)
│       └── CREATE_PAYROLL_SYSTEM.sql       ✅ Step D (반드시 실행)
│
├── 🌐 직원용 웹 페이지
│   ├── employee_payroll_login.html         로그인 페이지
│   └── employee_payroll_dashboard.html     급여명세서 대시보드
│
└── 🏢 관리자 페이지
    └── index.html                           메인 관리 시스템 (수정됨)
```

---

## 🚀 배포 체크리스트

### Phase 1: 데이터베이스 설정 (2분)

```bash
☐ Supabase SQL Editor 접속
☐ database/EMPLOYEE_PASSWORD_SYSTEM.sql 실행
☐ database/CREATE_PAYROLL_SYSTEM.sql 실행
☐ 검증 쿼리 실행 (아래 참조)
```

**검증 쿼리**:
```sql
SELECT 
  EXISTS(SELECT 1 FROM information_schema.columns 
         WHERE table_name = 'employees' AND column_name = 'login_password') as password_system,
  EXISTS(SELECT 1 FROM information_schema.tables 
         WHERE table_name = 'payroll_statements') as payroll_system,
  EXISTS(SELECT 1 FROM information_schema.tables 
         WHERE table_name = 'employee_login_logs') as login_logs;
```

### Phase 2: Storage 설정 (1분)

```bash
☐ Supabase Dashboard → Storage
☐ Create Bucket: "payroll-statements"
☐ 설정: Public = OFF, File Size = 10MB, MIME = application/pdf
```

### Phase 3: 테스트 (2분)

```bash
☐ index.html 열기 → 데이터 관리 탭 → 비밀번호 관리 섹션 확인
☐ employee_payroll_login.html에서 테스트 로그인
☐ 비밀번호 변경 화면 확인
☐ employee_payroll_dashboard.html로 이동 확인
☐ 대시보드 통계 카드 표시 확인
```

---

## 🔍 주요 기능 빠른 참조

### 자동 비밀번호 설정
```javascript
// 신규 직원 등록 시
직원 이름: 홍길동
전화번호: 010-1234-5678
→ 비밀번호 자동 설정: "5678" (뒷자리 4자리)
```

### 직원 최초 로그인 프로세스
```
1. employee_payroll_login.html 접속
2. 이름 + 초기 비밀번호(전화번호 뒷자리) 입력
3. 로그인 성공 → 비밀번호 변경 화면 자동 표시
4. 새 비밀번호 설정
5. employee_payroll_dashboard.html로 자동 이동
```

### 관리자 비밀번호 관리
```
index.html → 데이터 관리 탭 → 스크롤 다운
→ "🔐 직원 로그인 비밀번호 관리" 섹션

기능:
• 통계 대시보드 (전체/변경완료/미변경/최근로그인)
• 직원 목록 테이블 (이름, 전화번호, 비밀번호, 변경일)
• 비밀번호 초기화 버튼
• Excel 내보내기
```

### 급여명세서 조회
```
employee_payroll_dashboard.html

기능:
• 월별 급여명세서 카드 표시
• "자세히 보기" → 새 탭에서 PDF 열기
• "다운로드" → 컴퓨터에 저장
• 자동 조회/다운로드 횟수 추적
```

---

## 🛠️ 문제 해결

### 자주 발생하는 문제

#### 1. 비밀번호가 자동 설정되지 않음
```sql
-- 트리거 확인
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'employees';

-- 없으면 EMPLOYEE_PASSWORD_SYSTEM.sql 재실행
```

#### 2. 관리자 페이지에 비밀번호 섹션이 안 보임
```javascript
// index.html 라인 ~3022 확인
this.loadPasswordManagement(); // 이 줄이 있어야 함
```

#### 3. 직원이 급여명세서를 볼 수 없음
```sql
-- auth_user_id 확인
SELECT id, name, auth_user_id FROM employees WHERE name = '직원이름';
-- NULL이면 직원 앱에서 회원가입 필요
```

#### 4. 파일 다운로드가 안 됨
```
Supabase Dashboard → Storage → payroll-statements 버킷 확인
설정: Public = OFF, File Size = 10MB
```

---

## 📊 시스템 통계

### 데이터베이스 테이블

| 테이블명 | 용도 | 레코드 예상 |
|----------|------|-------------|
| `employees` | 직원 정보 (비밀번호 추가) | ~100명 |
| `payroll_statements` | 급여명세서 | ~1,200건/년 |
| `employee_login_logs` | 로그인 이력 | ~24,000건/년 |
| `payroll_notifications` | 알림 이력 | ~1,200건/년 |

### 스토리지 요구사항

| 항목 | 크기 | 보관 기간 |
|------|------|-----------|
| 급여명세서 PDF | 500KB × 1,200건 = 600MB/년 | 3년 (법적 의무) |
| 로그인 기록 | ~1MB/년 | 무제한 |
| **총 예상 스토리지** | **~2GB** | - |

---

## 🔐 보안 설계

### Row Level Security (RLS) 정책

```sql
-- 직원: 본인 급여명세서만 조회
CREATE POLICY "Employees can view own payroll"
ON payroll_statements FOR SELECT
USING (employee_id IN (
  SELECT id FROM employees WHERE auth_user_id = auth.uid()
));

-- 관리자: 소속 단지 직원 급여명세서 관리
CREATE POLICY "Managers can manage apartment payroll"
ON payroll_statements FOR ALL
USING (
  employee_id IN (
    SELECT e.id FROM employees e
    JOIN managers m ON e.apartment_id = m.apartment_id
    WHERE m.auth_user_id = auth.uid()
  )
);
```

---

## 🎓 사용자 교육

### 관리자용 핵심 포인트
1. 신규 직원 등록 시 **이름과 전화번호만** 입력
2. 비밀번호는 **자동으로 전화번호 뒷자리 4자리**로 설정
3. 직원에게 초기 비밀번호 전달 (문자/구두)
4. 비밀번호 잊어버린 경우 **"비밀번호 초기화"** 버튼 클릭

### 직원용 핵심 포인트
1. 최초 로그인: 이름 + 관리자에게 받은 4자리 숫자
2. 로그인 후 **반드시 비밀번호 변경**
3. 급여명세서는 **대시보드에서 월별 조회**
4. 비밀번호 분실 시 **관리자에게 초기화 요청**

---

## 🌐 GitHub 저장소

**Repository**: https://github.com/acerogym45-netizen/BDXI-QR-attendance  
**Branch**: main  
**Latest Commit**: `b3bb93f` - docs: Add quick start deployment guide

### 최근 커밋 히스토리
```
b3bb93f docs: Add quick start deployment guide
c439fda docs: Add comprehensive project status summary
9504ebd feat: Add employee payroll dashboard and complete implementation guide
154d563 feat: Add employee login password management system
a836e73 feat: Add payroll statement auto-distribution system
```

---

## 📞 추가 지원

### 더 자세한 정보가 필요하면

- **배포가 처음이라면**: `QUICK_START.md` 읽기
- **전체 시스템 이해**: `PROJECT_STATUS_SUMMARY.md` 읽기
- **비밀번호 시스템**: `EMPLOYEE_PASSWORD_GUIDE.md` 읽기
- **급여 시스템**: `PAYROLL_SYSTEM_GUIDE.md` 읽기
- **상세 구현**: `PAYROLL_IMPLEMENTATION_GUIDE.md` 읽기

### 문제가 생기면

1. 각 가이드의 "문제 해결" 섹션 확인
2. Git 커밋 히스토리에서 변경 사항 추적
3. 모든 코드에 한글 주석 포함

---

## ✅ 완료 상태

- [x] 직원 비밀번호 관리 시스템 코드 완성
- [x] 급여명세서 배포 시스템 코드 완성
- [x] 직원 로그인 페이지 완성
- [x] 직원 급여명세서 대시보드 완성
- [x] 관리자 페이지 비밀번호 관리 섹션 추가
- [x] 완전한 가이드 문서 작성
- [x] Git 커밋 & 푸시 완료
- [ ] Supabase SQL 스크립트 실행 (사용자 작업 대기)
- [ ] Supabase Storage 버킷 생성 (사용자 작업 대기)
- [ ] 시스템 테스트 (사용자 작업 대기)

---

**프로젝트 상태**: ✅ **코드 100% 완성, 배포 준비 완료**  
**다음 단계**: `QUICK_START.md` 파일을 열어서 3단계 배포 시작!  
**소요 시간**: 약 5분

---

*이 문서는 2026-05-11에 생성되었습니다.*
