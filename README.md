# 🏢 Facility Management Hub

통합 시설 관리 플랫폼 (아파트/빌딩 ERP + 필라테스/헬스장 CRM)

## 📋 시스템 구성

### 🏠 아파트/빌딩 관리 (ERP)
- 직원 출퇴근 관리
- 근태표 자동 생성 (PDF, 한글 폰트 지원)
- 구매 요청/검수
- 휴가 관리
- 민원 관리

### 💪 필라테스/헬스장 관리 (CRM)
- 회원 출석 체크인
- 강사 관리
- 프로그램 관리
- 회원 문의 관리
- 공지사항 관리

## 🚀 기술 스택

### Frontend
- **Framework**: Vue.js (ERP), Vanilla JavaScript (CRM)
- **Styling**: Tailwind CSS
- **PDF Generation**: jsPDF + autoTable + Paperlogy 폰트
- **QR Code**: QRCode.js
- **Charts**: Chart.js

### Backend
- **Database**: Supabase (PostgreSQL)
- **Real-time**: Supabase Realtime subscriptions
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage

## 🗂️ 프로젝트 구조

```
facility-management-hub/
├── facilities.html          # 시설 선택 랜딩 페이지
├── shared-config.js         # 공통 Supabase 설정
├── apartment/               # ERP 시스템 (아파트/빌딩)
│   ├── index.html          # 대시보드
│   ├── scan.html           # QR 출퇴근 체크
│   ├── master_dashboard.html  # 총괄 관리자
│   └── paperlogy_fonts.js  # PDF 한글 폰트
└── fitness/                 # CRM 시스템 (필라테스/헬스장)
    ├── index.html          # 레슨 신청
    ├── admin-main.html     # 관리자 대시보드
    ├── admin-instructors.html
    ├── admin-programs.html
    └── admin-inquiry.html
```

## 🔧 설치 및 실행

### 1. Supabase 프로젝트 설정

#### 데이터베이스 스키마 생성
Supabase SQL Editor에서 다음 테이블 생성:
- `facilities` - 시설 정보
- `employees` - 직원 정보 (ERP)
- `members` - 회원 정보 (CRM)
- `attendance_records` - 출퇴근/출석 기록
- `apartments`, `vacations`, `purchases`, `complaints` (ERP)
- `instructors`, `programs`, `inquiries`, `notices` (CRM)

#### 환경 설정
`shared-config.js` 파일에서 Supabase 설정:
```javascript
const SHARED_SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SHARED_SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

### 2. 로컬 개발 서버

정적 HTML이므로 HTTP 서버로 실행:

```bash
# Python
python -m http.server 8000

# Node.js
npx http-server -p 8000

# VS Code Live Server
# HTML 파일 우클릭 → Open with Live Server
```

### 3. Vercel 배포

```bash
# Vercel CLI 설치
npm install -g vercel

# 배포
vercel --prod
```

## 📊 데이터베이스 스키마

### 멀티 테넌시 설계

모든 테이블에 `facility_id` 컬럼 추가로 시설별 데이터 격리:

```sql
-- 시설 정보
facilities (id, name, type, address, phone)
  ├─ type: 'apartment' | 'fitness'

-- ERP: 직원
employees (id, facility_id, name, position, qr_code)

-- CRM: 회원
members (id, facility_id, name, phone, membership_type, qr_code)

-- 공통: 출퇴근/출석
attendance_records (id, facility_id, employee_id, member_id, check_in_time)
```

## 🎨 주요 기능

### QR 기반 출퇴근/출석
- 스마트폰으로 QR 스캔
- 실시간 체크인/아웃
- 자동 기록 저장

### PDF 근태표 생성
- 월별 출퇴근 현황 자동 생성
- Paperlogy 한글 폰트 임베딩
- A4 가로 형식, 단일 페이지

### 실시간 대시보드
- Chart.js 차트
- 실시간 데이터 업데이트
- Supabase Realtime

## 🔐 보안

### Row Level Security (RLS)
- Supabase RLS 정책으로 시설별 데이터 격리
- 개발 환경에서는 모든 접근 허용
- 프로덕션에서는 인증 기반 제한

### 환경 변수
- Supabase URL/Key는 `shared-config.js`에서 관리
- 민감 정보는 환경 변수로 이관 권장

## 🌐 배포 URL

- **Production**: TBD (Vercel)
- **Supabase**: https://awqatgkfrzusbidzosrx.supabase.co

## 📝 개발 로그

### v1.0.0 (2026-05-19)
- ✅ GitHub 저장소 생성
- ✅ Supabase 데이터베이스 설정
- ✅ ERP + CRM 통합 구조
- ✅ 시설 선택 랜딩 페이지
- ✅ 공통 설정 파일 (`shared-config.js`)

## 📞 문의

- **Email**: support@example.com
- **GitHub**: https://github.com/acerogym45-netizen/facility-management-hub

## 📄 라이센스

Copyright © 2026 Facility Management Hub. All rights reserved.

---

**Powered by Supabase + Tailwind CSS**
