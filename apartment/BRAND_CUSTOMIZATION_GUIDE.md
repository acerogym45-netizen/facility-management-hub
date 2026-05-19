# 브랜드 커스터마이징 시스템 가이드 🎨

## 📋 개요

이제 코드 수정 없이 로고, 회사명, 색상 등을 간편하게 변경할 수 있습니다!
다른 기업에 판매할 때 쉽게 브랜드를 커스터마이징할 수 있는 시스템입니다.

---

## ✅ 구현된 기능

### 1. 브랜드 설정 항목
- ✅ **회사명 (한글)**: 예) 마스터플랜리소스(유)
- ✅ **회사명 (영문)**: 예) MasterPlanResource Co.,Ltd.
- ✅ **로고 이미지 URL**: Supabase Storage 또는 외부 URL
- ✅ **주 색상**: 브랜드 메인 컬러 (HEX)
- ✅ **보조 색상**: 브랜드 보조 컬러 (HEX)
- ✅ **로그인 부제목**: 예) "직원 업무 관리 시스템"
- ✅ **총괄 관리자 타이틀**: 예) "총괄 관리자"

### 2. 자동 적용 위치
- ✅ 로그인 화면 로고
- ✅ 대시보드 헤더 로고
- ✅ 회사명 텍스트
- ✅ 페이지 제목 (Title)
- ✅ 마스터 대시보드 헤더
- ✅ 이메일 주소 표시

---

## 🚀 사용 방법

### 1단계: 데이터베이스 테이블 생성

Supabase 대시보드에서 SQL 실행:

```bash
# SQL 파일 위치
/home/user/webapp/database/CREATE_BRAND_SETTINGS.sql
```

이 파일을 Supabase SQL Editor에서 실행하면:
- `brand_settings` 테이블 생성
- RLS 정책 설정 (읽기: 모두, 쓰기: 인증된 사용자)
- 기본 브랜드 설정 자동 삽입 (마스터플랜리소스)

### 2단계: 브랜드 설정 페이지 접속

1. 마스터 대시보드 로그인
2. 우측 상단 "브랜드 설정" 버튼 클릭
3. 또는 직접 URL 접속: `brand_settings.html`

### 3단계: 설정 입력

**회사명 입력:**
```
한글: 마스터플랜리소스(유)
영문: MasterPlanResource Co.,Ltd.
```

**로고 이미지 (선택사항):**
- Supabase Storage에 로고 업로드
- Public URL 복사하여 입력
- 비워두면 회사명 텍스트로 표시

**색상 선택:**
```
주 색상: #C5A35F (골드)
보조 색상: #D4AF37 (골드)
```

**텍스트 설정:**
```
로그인 부제목: 직원 업무 관리 시스템
총괄 관리자 타이틀: 총괄 관리자
```

### 4단계: 저장 및 적용

1. "설정 저장" 버튼 클릭
2. 성공 메시지 확인
3. **메인 페이지 새로고침** (F5)
4. 변경사항 자동 적용 확인

---

## 📸 로고 이미지 업로드 방법

### 🎯 방법 1: 직접 파일 업로드 (권장) ⭐

브랜드 설정 페이지에서 직접 업로드:

1. 브랜드 설정 페이지 접속
2. "로고 이미지" 섹션에서 파일 선택 버튼 클릭
3. PNG, JPG, SVG 파일 선택 (최대 2MB)
4. 자동으로 Supabase Storage에 업로드됨
5. Public URL이 자동으로 저장됨
6. 미리보기에서 즉시 확인 가능

**장점:**
- ✅ URL 복사/붙여넣기 불필요
- ✅ 자동으로 Storage 업로드
- ✅ 즉시 미리보기 가능
- ✅ 파일 크기 자동 검증

### 방법 2: Supabase Storage 수동 업로드

1. Supabase 대시보드 → Storage
2. `brand-assets` 버킷 선택 (없으면 생성)
3. 로고 이미지 업로드 (PNG, SVG 권장)
4. Public URL 복사
5. 브랜드 설정에 붙여넣기

**예시 URL:**
```
https://qgpqhtuynxhmgawakjxe.supabase.co/storage/v1/object/public/brand-assets/logo.png
```

### 방법 3: 외부 URL 사용

CDN이나 다른 호스팅에 업로드한 이미지도 사용 가능:
```
https://cdn.example.com/logo.png
```

### ⚠️ Storage 설정 필수

파일 업로드 기능을 사용하려면 먼저 Supabase에서 Storage 버킷을 설정해야 합니다:

```bash
# SQL 파일 위치
/home/user/webapp/database/CREATE_STORAGE_BRAND_ASSETS.sql
```

이 파일을 Supabase SQL Editor에서 실행하면:
- ✅ `brand-assets` Storage 버킷 생성
- ✅ Public 접근 권한 설정
- ✅ 업로드 정책 설정 (anon 사용자도 업로드 가능)
- ✅ 읽기 정책 설정 (모두 읽기 가능)

---

## 🎨 미리보기 기능

브랜드 설정 페이지에서:
- ✅ 실시간 미리보기
- ✅ 로고 표시 확인
- ✅ 색상 조합 확인
- ✅ 텍스트 표시 확인

설정을 변경하면 즉시 미리보기에 반영됩니다!

---

## 🔄 다른 기업에 판매할 때

### 빠른 커스터마이징 절차:

**1. 마스터 대시보드 로그인**
```
URL: master_dashboard.html
PIN: master2026
```

**2. 브랜드 설정 클릭**

**3. 고객사 정보 입력:**
```
회사명: (주)카인드원
회사명 영문: KindOne Co.,Ltd.
로고: https://kindone.com/logo.png
주 색상: #2C5F2D (카인드원 그린)
보조 색상: #4CAF50
```

**4. 저장 및 테스트**

**소요 시간: 약 5분**

---

## 💡 사용 팁

### 로고 없이 사용하는 경우
로고 URL을 비워두면:
- 회사명이 텍스트로 표시됨
- 주 색상으로 자동 스타일링
- 깔끔한 텍스트 로고 효과

### 색상 선택 가이드
```
보수적: #2C5F2D (녹색), #1B4D3E (진녹색)
현대적: #667eea (보라), #764ba2 (진보라)
고급스러움: #C5A35F (골드), #D4AF37 (골드)
신뢰감: #1E3A8A (네이비), #3B82F6 (블루)
```

### 파일 형식 권장사항
```
로고: PNG (투명 배경), SVG (벡터)
크기: 최대 200KB
해상도: 최소 512x512px
```

---

## 🔧 기술 상세

### 데이터베이스 구조
```sql
brand_settings 테이블:
- id (UUID)
- company_name (TEXT) - 한글 회사명
- company_name_en (TEXT) - 영문 회사명  
- logo_url (TEXT) - 로고 이미지 URL
- primary_color (TEXT) - 주 색상 HEX
- secondary_color (TEXT) - 보조 색상 HEX
- login_subtitle (TEXT) - 로그인 부제목
- master_dashboard_title (TEXT) - 마스터 타이틀
- is_active (BOOLEAN) - 활성화 여부
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### 로드 프로세스
```javascript
1. app.init() 실행
2. loadBrandSettings() 호출
3. Supabase에서 최신 설정 로드
4. applyBrandSettings() 실행
5. DOM 요소 자동 업데이트
```

### 대체 로직 (Fallback)
브랜드 설정이 없거나 로드 실패 시:
```javascript
기본값 사용:
- 회사명: 마스터플랜리소스(유)
- 색상: #C5A35F (골드)
- 로고: 텍스트로 표시
```

---

## 📂 관련 파일

### 새로 추가된 파일
```
/home/user/webapp/
├── brand_settings.html                    # 브랜드 설정 관리 페이지
└── database/
    ├── CREATE_BRAND_SETTINGS.sql          # 테이블 생성 SQL
    └── CREATE_STORAGE_BRAND_ASSETS.sql    # Storage 버킷 생성 SQL
```

### 수정된 파일
```
├── index.html                   # 브랜드 로드/적용 로직 추가
└── master_dashboard.html        # 타이틀/버튼 업데이트
```

---

## ✅ 체크리스트

### 최초 설정 시:
- [ ] CREATE_BRAND_SETTINGS.sql 실행
- [ ] CREATE_STORAGE_BRAND_ASSETS.sql 실행 (파일 업로드 사용 시)
- [ ] 기본 데이터 삽입 확인
- [ ] RLS 정책 활성화 확인
- [ ] Storage 버킷 생성 확인
- [ ] 브랜드 설정 페이지 접속 테스트
- [ ] 로고 파일 업로드 테스트
- [ ] 설정 저장 테스트
- [ ] 메인 페이지에서 적용 확인

### 고객사 변경 시:
- [ ] 로고 이미지 준비 (PNG/SVG, 2MB 이하)
- [ ] 브랜드 설정 페이지에서 직접 파일 업로드
- [ ] 회사명 및 색상 입력
- [ ] 미리보기 확인
- [ ] 저장
- [ ] 새로고침하여 확인

---

## 🆘 문제 해결

### Q: 브랜드 설정이 적용 안 됨
**A:** 페이지 새로고침 (Ctrl+F5) 하세요. 캐시 문제일 수 있습니다.

### Q: 로고가 안 보임
**A:** 
1. URL이 올바른지 확인
2. Supabase Storage 버킷이 Public인지 확인
3. 이미지 파일이 실제로 존재하는지 확인

### Q: 파일 업로드가 안 됨
**A:** 
1. **Storage 버킷 없음 오류:**
   - `CREATE_STORAGE_BRAND_ASSETS.sql` 실행
   - Supabase Storage에서 `brand-assets` 버킷 확인
   
2. **권한 오류:**
   - SQL에서 Storage RLS 정책 확인
   - Public Upload 정책이 활성화되어 있는지 확인
   
3. **파일 크기 오류:**
   - 2MB 이하 이미지 사용
   - PNG, JPG, SVG 형식 확인

4. **네트워크 오류:**
   - 인터넷 연결 확인
   - Supabase 프로젝트 활성 상태 확인

### Q: 색상이 적용 안 됨
**A:** HEX 코드 형식 확인 (`#RRGGBB`)

### Q: 테이블 생성 오류
**A:** 
1. SQL 파일 전체 실행했는지 확인
2. Supabase 연결 확인
3. 권한 문제 확인

---

## 🎉 완료!

이제 코드 수정 없이 간편하게 브랜드를 커스터마이징할 수 있습니다!

**주요 기능:**
- ✅ 직접 파일 업로드로 로고 등록
- ✅ 실시간 미리보기
- ✅ 자동 Storage 업로드
- ✅ 화이트 라벨링 지원

**커밋**: 9c2865e  
**상태**: ✅ Production Ready  
**마지막 업데이트**: 2026-05-11
