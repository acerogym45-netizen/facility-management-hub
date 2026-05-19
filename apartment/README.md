# 봉담자이프라이드시티 QR 출석 체크 시스템

QR 코드 스캔을 통한 직원 출석 관리 시스템입니다. 직원이 각 구역에 부착된 QR 코드를 스캔하여 출석을 체크하고, 관리자가 출석 현황을 실시간으로 확인할 수 있습니다.

## 📋 프로젝트 개요

### 주요 기능

#### 📊 출석 관리
- ✅ **아파트 다중 관리**: 여러 아파트 등록 및 선택 기능 (NEW!)
- ✅ **직원 관리**: 직원 등록, 수정, 삭제 및 상태 관리
- ✅ **계약기간 관리**: 직원별 계약 시작/종료일 관리 (NEW!)
- ✅ **계약 만료 알림**: 30일 이내 만료 직원 자동 알림 (NEW!)
- ✅ **구역 관리**: 출석 체크 구역 등록 및 관리
- ✅ **QR 코드 생성**: 각 구역별 QR 코드 자동 생성 및 인쇄
- ✅ **모바일 스캔**: 스마트폰 카메라로 QR 코드 스캔
- ✅ **출석 기록**: 자동 시간 기록 및 데이터 저장 (출근/퇴근/휴게 시작/휴게 종료)
- ✅ **통계 분석**: 일별/구역별 출석 현황 차트
- ✅ **데이터 내보내기**: CSV 파일로 출석 기록 다운로드

#### 🧹 청소 업무 관리 (NEW!)
- ✅ **청소 기록**: 사진과 함께 청소 작업 기록
- ✅ **실시간 사진 업로드**: 최대 30장의 사진 동시 업로드
- ✅ **보안 검증**: 10분 이내 촬영한 사진만 업로드 가능 (EXIF 메타데이터 검증)
- ✅ **중복 방지**: 동일 사진 재사용 차단 (해시 검증)
- ✅ **체크리스트**: 구역별 맞춤 청소 항목 체크
- ✅ **실시간 대시보드**: 오늘의 청소 현황 한눈에 확인
- ✅ **사진 갤러리**: 날짜/구역별 청소 사진 조회
- ✅ **통계 분석**: 직원별/구역별/주간 청소 통계

### 워크플로우

#### 출석 관리 워크플로우
1. **관리자**: 직원 및 구역 등록
2. **관리자**: 구역별 QR 코드 생성 및 인쇄
3. **관리자**: 각 구역에 QR 코드 부착
4. **직원**: 스캔 페이지에서 본인 선택
5. **직원**: 출석 유형 선택 (출근/퇴근/휴게 시작/휴게 종료)
6. **시스템**: 자동으로 출석 시간 및 위치 기록
7. **관리자**: 출석 기록 조회 및 통계 확인

#### 청소 업무 워크플로우 (NEW!)
1. **직원**: 청소 기록 페이지(`work.html`) 접속
2. **직원**: 본인 선택 → 청소 구역 선택
3. **직원**: 청소 항목 체크리스트 확인 (선택사항)
4. **직원**: 청소 후 실시간 사진 촬영 (최대 30장)
5. **시스템**: 사진 촬영 시간 자동 검증 (10분 이내)
6. **시스템**: 사진 중복 방지 해시 검증
7. **직원**: 메모 작성 (선택사항) → 제출
8. **관리자**: 청소 대시보드(`work-admin.html`)에서 실시간 확인

## 🌐 페이지 구조

### 📊 출석 관리 페이지

#### 1. 관리자 페이지 (`index.html`)
- **경로**: `/` 또는 `/index.html`
- **기능**:
  - 🏢 **아파트 선택**: 로그인 시 관리할 아파트 선택 (NEW!)
  - 👤 **직원 관리**: 등록/삭제/상태 변경/계약기간 관리 (NEW!)
  - 📋 **계약 만료 알림**: 30일 이내 만료 직원 자동 알림 배너 (NEW!)
  - 📍 **구역 관리**: 등록/삭제/상태 변경
  - 🔢 **QR 코드 생성**: 구역별 QR 코드 생성 및 인쇄
  - 🧹 **청소 갤러리**: Before/After 사진, 다중 사진 그룹핑 (NEW!)
  - 📊 **통계 분석**: 아파트별 필터링된 데이터 조회

#### 2. QR 스캔 페이지 (`scan.html`)
- **경로**: `/scan.html`
- **기능**:
  - 직원 선택 (검색 기능 포함)
  - 출석 유형 선택 (출근/퇴근/휴게 시작/휴게 종료)
  - 실시간 출석 체크
  - 5분 세션 타이머
  - 최근 스캔 기록 표시

#### 3. 출석 기록 페이지 (`records.html`)
- **경로**: `/records.html`
- **기능**:
  - 전체/오늘 출석 통계
  - 최근 7일 출석 현황 차트
  - 구역별 출석 분포 차트
  - 날짜/직원/구역별 필터링
  - CSV 파일 내보내기

### 🧹 청소 관리 페이지 (NEW!)

#### 4. 청소 기록 페이지 (`work.html`)
- **경로**: `/work.html`
- **대상**: 직원용
- **기능**:
  - 직원 선택 (검색 기능 포함)
  - 청소 구역 선택
  - 구역별 맞춤 체크리스트 (8가지 구역 타입)
  - 실시간 사진 촬영 (최대 30장)
  - EXIF 메타데이터 검증 (10분 이내 촬영 사진만 허용)
  - 사진 해시 검증 (중복 방지)
  - 업로드 진행률 표시
  - 메모 작성 (선택사항)

#### 5. 청소 대시보드 (`work-admin.html`)
- **경로**: `/work-admin.html`
- **대상**: 관리자용
- **탭 구성**:
  - **현황 탭**: 오늘의 통계, 구역별 현황, 최근 기록
  - **갤러리 탭**: 날짜/구역별 사진 갤러리, 사진 확대 보기
  - **기록 탭**: 상세 청소 기록 조회, 다중 필터링
  - **통계 탭**: 직원별/구역별/주간 통계 시각화

## 🗄️ 데이터베이스 구조

### 출석 관리 테이블

#### 1. employees (직원 테이블)
| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID | 직원 고유 ID (자동 생성) |
| name | text | 직원 이름 |
| employee_number | text | 사번 |
| department | text | 부서 |
| position | text | 직책 |
| phone | text | 연락처 |
| is_active | bool | 활성 상태 |

#### 2. locations (구역 테이블)
| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID | 구역 고유 ID (자동 생성) |
| name | text | 구역 이름 |
| code | text | 구역 코드 (QR에 사용) |
| building | text | 건물/동 |
| floor | text | 층 |
| description | text | 구역 설명 |
| is_active | bool | 활성 상태 |

#### 3. attendance_records (출석 기록 테이블)
| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID | 출석 기록 ID (자동 생성) |
| employee_id | UUID | 직원 ID |
| employee_name | text | 직원 이름 |
| employee_number | text | 사번 |
| location_id | UUID | 구역 ID |
| location_name | text | 구역 이름 |
| location_code | text | 구역 코드 |
| attendance_type | text | 출석 유형 (출근/퇴근/휴게 시작/휴게 종료) |
| scan_time | timestamptz | 스캔 시간 |
| device_info | text | 스캔 기기 정보 |

### 청소 관리 테이블 (NEW!)

#### 4. cleaning_tasks (청소 작업 테이블)
| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID | 작업 ID (자동 생성) |
| employee_id | UUID | 직원 ID |
| employee_name | text | 직원 이름 |
| employee_number | text | 사번 |
| location_id | UUID | 구역 ID |
| location_name | text | 구역 이름 |
| location_code | text | 구역 코드 |
| checklist_items | JSONB | 체크한 항목 배열 |
| photo_urls | JSONB | 사진 URL 배열 (최대 30개) |
| photo_hashes | JSONB | 사진 해시 배열 (중복 방지용) |
| photo_count | integer | 사진 개수 |
| notes | text | 메모 |
| photo_taken_at | timestamptz | 첫 사진 촬영 시간 |
| submitted_at | timestamptz | 제출 시간 |
| status | text | 상태 (completed) |
| device_info | text | 기기 정보 |
| created_at | timestamptz | 생성 시간 |
| updated_at | timestamptz | 수정 시간 |

### 저장소 (Storage)

#### cleaning-photos (청소 사진 버킷)
- **용도**: 청소 작업 사진 저장
- **접근**: Public (URL 접근 가능)
- **파일명 형식**: `{timestamp}_{location_code}_{employee_name}_{original_name}`
- **최대 용량**: 1GB (무료 플랜)

## 🚀 사용 방법

### 📊 출석 관리 시스템

#### 초기 설정

1. **관리자 페이지 접속**: `index.html`
2. **직원 등록**:
   - "직원 관리" 탭에서 직원 정보 입력
   - 이름, 사번은 필수 입력
   - 부서, 직책, 연락처는 선택 입력
3. **구역 등록**:
   - "구역 관리" 탭에서 구역 정보 입력
   - 구역 이름, 구역 코드는 필수 입력
   - 건물/동, 층, 설명은 선택 입력

#### QR 코드 생성 및 부착

1. **QR 코드 생성**:
   - "QR 코드 생성" 탭 클릭
   - 등록된 모든 활성 구역의 QR 코드가 자동 생성
2. **QR 코드 인쇄**:
   - 각 구역 카드의 "인쇄하기" 버튼 클릭
   - 인쇄 미리보기에서 인쇄 또는 PDF 저장
3. **QR 코드 부착**:
   - 인쇄된 QR 코드를 해당 구역에 부착
   - 직원들이 쉽게 스캔할 수 있는 위치 선택

#### 출석 체크 (직원용)

1. **스캔 페이지 접속**: `scan.html` (모바일 권장)
2. **직원 선택**:
   - 검색창에 이름 또는 사번 입력
   - 본인 카드 클릭
3. **출석 유형 선택**:
   - 출근 / 퇴근 / 휴게 시작 / 휴게 종료 중 선택
4. **출석 완료**:
   - 자동으로 출석 체크 완료
   - "계속 스캔하기" 또는 "직원 변경" 가능

#### 출석 기록 확인 (관리자용)

1. **출석 기록 페이지 접속**: `records.html`
2. **통계 확인**:
   - 상단 카드에서 전체/오늘 출석, 활성 직원/구역 확인
   - 최근 7일 출석 현황 차트 확인
   - 구역별 출석 분포 차트 확인
3. **상세 기록 조회**:
   - 날짜 범위 설정
   - 직원 또는 구역으로 검색
   - "검색" 버튼 클릭
4. **데이터 내보내기**:
   - "엑셀 내보내기" 버튼 클릭
   - CSV 파일 다운로드

---

## 🧹 청소 관리 시스템 (NEW!)

#### 🔥 중요: 데이터베이스 스키마 업데이트 필수

**Before/After 및 다중 사진 기능을 사용하려면 먼저 데이터베이스를 업데이트해야 합니다!**

1. **Supabase 대시보드 접속**:
   - Supabase 프로젝트 → SQL Editor 메뉴
   
2. **New Query 생성 후 실행**:
   
   📄 [`add-before-after-column.sql`](./add-before-after-column.sql) 파일 내용을 복사하여 실행하거나, 아래 SQL을 직접 실행:

   ```sql
   -- Before/After 컬럼 추가 (before, after, null)
   ALTER TABLE cleaning_tasks 
   ADD COLUMN IF NOT EXISTS before_after TEXT;

   -- 다중 사진 URL 배열 (JSONB)
   ALTER TABLE cleaning_tasks 
   ADD COLUMN IF NOT EXISTS photo_urls JSONB DEFAULT '[]'::jsonb;

   -- 사진 개수
   ALTER TABLE cleaning_tasks 
   ADD COLUMN IF NOT EXISTS photo_count INTEGER DEFAULT 1;

   -- 사진 순서 (0=before, 1=after)
   ALTER TABLE cleaning_tasks 
   ADD COLUMN IF NOT EXISTS photo_order INTEGER DEFAULT 0;

   -- 업로드 타입 (single, multi, before_after)
   ALTER TABLE cleaning_tasks 
   ADD COLUMN IF NOT EXISTS upload_type TEXT DEFAULT 'single';

   -- 인덱스 생성
   CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_before_after 
   ON cleaning_tasks(before_after);

   CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_group_id 
   ON cleaning_tasks(group_id);

   CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_upload_type 
   ON cleaning_tasks(upload_type);
   ```

3. **확인**:
   ```sql
   SELECT column_name, data_type, is_nullable, column_default
   FROM information_schema.columns
   WHERE table_name = 'cleaning_tasks' 
   AND column_name IN ('before_after', 'photo_count', 'photo_urls', 'group_id', 'photo_order', 'upload_type')
   ORDER BY column_name;
   ```
   
   6개의 컬럼이 보여야 합니다! ✅

---

#### 🏢 NEW: 아파트 다중 관리 및 직원 계약기간 관리 (v2.0)

**신규 기능 추가를 위한 데이터베이스 업데이트:**

📄 **1단계**: [`add-apartment-and-contract-features.sql`](./add-apartment-and-contract-features.sql) 파일을 Supabase SQL Editor에서 실행하세요!

**주요 기능:**
1. **아파트 다중 관리**: 카인드원이 관리하는 여러 아파트를 등록하고 선택
2. **직원 계약기간 관리**: 계약 시작/종료일 관리 및 만료 알림
3. **아파트별 데이터 필터링**: 선택한 아파트의 데이터만 조회

**데이터베이스 변경사항:**
- `apartments` 테이블 생성 (아파트 정보)
- 모든 테이블에 `apartment_id` 외래키 추가
- `employees` 테이블에 `contract_start`, `contract_end`, `notes` 추가
- 계약 만료 임박 직원 조회 함수 (`get_contract_expiring_employees`)

📄 **2단계**: [`migrate-existing-data.sql`](./migrate-existing-data.sql) 파일을 Supabase SQL Editor에서 실행하세요!

**기존 데이터 마이그레이션:**
- 봉담자이프라이드시티 아파트 추가 (APT004)
- 기존 데이터를 봉담자이프라이드시티에 자동 연결
- 직원, 구역, 청소 작업, 출석 기록 모두 마이그레이션

**주의사항:**
- 1단계를 먼저 실행한 후 2단계를 실행하세요
- 기존 데이터가 있는 경우 반드시 2단계를 실행하여 `apartment_id`를 연결해야 합니다

---

#### 초기 설정 (Supabase)

1. **Storage 버킷 생성**:
   - Supabase 대시보드 → Storage 메뉴
   - 새 버킷 생성: `cleaning-photos`
   - **Public bucket** 체크 ✅
   
2. **Storage 정책 설정**:
   ```sql
   -- 업로드 허용
   CREATE POLICY "Allow public uploads"
   ON storage.objects FOR INSERT
   WITH CHECK (bucket_id = 'cleaning-photos');
   
   -- 읽기 허용
   CREATE POLICY "Allow public reads"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'cleaning-photos');
