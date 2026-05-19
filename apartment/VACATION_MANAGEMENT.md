# 휴가 관리 시스템 (Vacation Management System)

## 📋 개요 (Overview)

휴가 관리 시스템이 **근태 관리 탭 내부의 서브 카테고리**로 구현되었습니다.
- **위치**: 근태 관리 탭 → 하단 스크롤 → 휴가 관리 섹션
- **이유**: 탭이 너무 많아지면 사용자 경험이 복잡해지므로, 기존 탭 안에 통합

---

## 🎯 주요 기능 (Key Features)

### 1. 휴가 통계 대시보드
4개의 실시간 통계 카드:
- **총 사용 휴가**: 승인된 전체 휴가 일수
- **휴가 승인율**: (승인 건수 / 전체 신청 건수) × 100%
- **승인 대기**: 현재 대기 중인 휴가 신청 건수
- **이번달 휴가**: 이번 달에 승인된 휴가 일수

### 2. 휴가 사용 내역 테이블
**컬럼**: 직원명, 휴가 유형, 시작일, 종료일, 일수, 사유, 상태, 관리

**필터 기능**:
- 직원별 필터
- 상태별 필터 (승인됨, 대기중, 거부됨)
- 기간별 필터 (전체, 이번 달, 지난 달, 올해)

**상태 뱃지**:
- 🟢 승인됨 (초록)
- 🟡 대기중 (노랑)
- 🔴 거부됨 (빨강)

**관리 버튼**:
- 대기중 상태: 승인/거부 버튼 표시
- 승인됨/거부됨: "-" 표시

### 3. 직원별 잔여 휴가
각 직원의:
- 총 휴가 일수 (근속년수 기반 자동 계산)
- 사용한 일수
- 남은 일수
- 시각적 진행률 바 (사용률에 따라 색상 변경)
  - 0-50%: 초록색
  - 50-80%: 노란색
  - 80-100%: 빨간색

### 4. 휴가 정책 안내
**연차 휴가**:
- 입사 1년 미만: 11일
- 입사 1년 후: 15일
- 입사 3년 후: 16일
- 이후 2년마다 1일 가산 (최대 25일)

**병가**:
- 진단서 제출 시 인정
- 연간 최대 10일

**경조사 휴가**:
- 본인 결혼: 5일
- 직계 존비속 사망: 5일
- 형제/자매 결혼: 1일

**기타 사항**:
- 휴가 신청은 3일 전까지
- 긴급 휴가는 당일 연락 필수
- 미사용 연차는 다음 해 소멸

### 5. 휴가 신청 가이드
4단계 신청 프로세스:
1. 직원 앱에서 '휴가 신청' 메뉴 선택
2. 휴가 유형, 날짜, 사유 입력
3. 관리자 승인 대기
4. 승인 시 자동으로 근태에 반영

---

## 🔧 구현된 함수들 (Implemented Functions)

### 통계 및 데이터 로드
```javascript
// 휴가 통계 카드 업데이트
app.loadVacationStats()

// 휴가 사용 내역 테이블 로드
app.loadVacationHistory()

// 직원별 잔여 휴가 로드
app.loadEmployeeVacationBalance()

// 전체 새로고침
app.refreshVacationHistory()
```

### 필터링 및 검색
```javascript
// 직원/상태/기간 필터 적용
app.filterVacationHistory()
```

### 데이터 내보내기
```javascript
// CSV 파일로 다운로드 (한글 지원)
app.exportVacationToExcel()
```

### 승인/거부 (기존 함수 연동)
```javascript
// 휴가 승인 (대시보드 자동 새로고침)
app.approveVacation(vacationId)

// 휴가 거부 (대시보드 자동 새로고침)
app.rejectVacation(vacationId)
```

### 유틸리티 함수
```javascript
// 상태 뱃지 HTML 생성
app.getVacationStatusBadge(status)

// 시작일-종료일 기반 일수 계산
app.calculateVacationDays(startDate, endDate)

// 근속년수 기반 총 휴가 일수 계산
app.calculateTotalVacationDays(hireDate)
```

---

## 🎨 UI/UX 구조

### 레이아웃
```
┌─────────────────────────────────────────────┐
│  근태 관리 탭                                 │
│  ├─ 출근 차단 알림                            │
│  ├─ 퇴근 미기록 알림                          │
│  ├─ 캘린더 뷰 (70%) + 실시간 현황 (30%)       │
│  └─ 근로시간 집계                             │
├─────────────────────────────────────────────┤
│  [경계선: 보라색 테두리]                       │
├─────────────────────────────────────────────┤
│  휴가 관리 섹션 (서브 카테고리)                │
│  ├─ 헤더: "휴가 관리" (보라색 아이콘)          │
│  ├─ 통계 카드 4개 (2컬럼 레이아웃)             │
│  ├─ 휴가 사용 내역 테이블 (필터 + 검색)        │
│  ├─ 월별 차트 (향후 구현 가능)                 │
│  └─ 사이드바 (1컬럼)                          │
│      ├─ 직원별 잔여 휴가                      │
│      ├─ 휴가 정책 안내                        │
│      └─ 휴가 신청 가이드                      │
└─────────────────────────────────────────────┘
```

### 색상 테마
- **주요 색상**: 보라색 (Purple #9333EA)
- **보조 색상**: 인디고 (Indigo #4F46E5)
- **배경**: 그라데이션 (Purple-50 to Indigo-50)
- **상태 색상**:
  - 초록: 승인됨
  - 노랑: 대기중
  - 빨강: 거부됨

---

## 📊 데이터베이스 스키마

### vacations 테이블 (기존)
```sql
- id: UUID (PK)
- apartment_id: UUID (FK)
- employee_id: UUID (FK)
- employee_name: TEXT
- vacation_type: TEXT (연차, 병가, 경조사 등)
- vacation_date: DATE (단일 날짜)
- start_date: DATE (휴가 시작일)
- end_date: DATE (휴가 종료일)
- reason: TEXT (사유)
- note: TEXT (메모)
- status: TEXT (pending, approved, rejected)
- approved_at: TIMESTAMP
- approved_by: TEXT
- admin_comment: TEXT (거부 사유)
- created_at: TIMESTAMP
```

---

## 🔄 자동 새로고침 로직

### 탭 전환 시
```javascript
switchTab('stats') 호출 시:
1. loadStats()
2. loadAttendanceCalendar()
3. loadOvertimeRecords()
4. loadTardinessRecords()
5. loadPendingVacations()
6. loadVacationStats()        ← 새로 추가
7. loadVacationHistory()      ← 새로 추가
8. loadEmployeeVacationBalance() ← 새로 추가
```

### 승인/거부 시
```javascript
approveVacation(id) 또는 rejectVacation(id) 호출 시:
1. 데이터베이스 업데이트
2. loadPendingVacations()
3. loadVacationStats()        ← 새로 추가
4. loadVacationHistory()      ← 새로 추가
5. loadEmployeeVacationBalance() ← 새로 추가
```

---

## 🚀 사용 방법 (How to Use)

### 관리자 (Admin Dashboard)

1. **휴가 내역 조회**:
   - 근태 관리 탭 클릭
   - 하단으로 스크롤하여 "휴가 관리" 섹션 확인
   - 통계 카드에서 현황 파악
   - 테이블에서 상세 내역 확인

2. **휴가 필터링**:
   - 직원 드롭다운: 특정 직원 선택
   - 상태 드롭다운: 승인됨/대기중/거부됨 선택
   - 기간 드롭다운: 이번 달/지난 달/올해 선택

3. **휴가 승인/거부**:
   - 대기중 상태의 휴가 찾기
   - ✅ 버튼: 승인
   - ❌ 버튼: 거부 (사유 입력 필요)

4. **데이터 내보내기**:
   - "Excel 다운로드" 버튼 클릭
   - CSV 파일 자동 다운로드 (한글 깨짐 방지 BOM 포함)

5. **잔여 휴가 확인**:
   - 오른쪽 사이드바 → "직원별 잔여 휴가"
   - 각 직원의 사용률 확인
   - 빨간색 바: 휴가 거의 소진 (80% 이상)

### 직원 (Employee App)
- 직원 앱에서 휴가 신청
- 관리자가 대시보드에서 승인/거부
- 승인 시 자동으로 근태에 반영

---

## 🐛 알려진 제한사항 (Known Limitations)

1. **월별 차트**: 현재 미구현 (향후 Chart.js 추가 예정)
2. **다중 날짜 선택**: 현재 start_date, end_date 기반 (단일 vacation_date도 지원)
3. **휴가 유형 커스터마이징**: 하드코딩된 유형 (연차, 병가, 경조사 등)

---

## ✅ 테스트 체크리스트

- [x] 휴가 통계 카드 로드
- [x] 휴가 내역 테이블 로드
- [x] 직원 필터 작동
- [x] 상태 필터 작동
- [x] 기간 필터 작동
- [x] 승인 버튼 작동 + 자동 새로고침
- [x] 거부 버튼 작동 + 자동 새로고침
- [x] Excel 다운로드 (한글 포함)
- [x] 잔여 휴가 계산 (근속년수 기반)
- [x] 진행률 바 색상 변경
- [x] 탭 전환 시 자동 로드
- [x] 반응형 레이아웃 (모바일/태블릿)

---

## 📝 향후 개선 사항 (Future Improvements)

1. **월별 차트 추가**:
   ```javascript
   // Chart.js 사용하여 월별 휴가 사용 추이 시각화
   // 캔버스: <canvas id="vacation-monthly-chart"></canvas>
   ```

2. **휴가 종류별 통계**:
   - 연차 vs 병가 vs 경조사 비율
   - 파이 차트 또는 도넛 차트

3. **직원별 상세 페이지**:
   - 클릭 시 모달로 직원별 휴가 히스토리
   - 연도별 휴가 사용 패턴

4. **알림 시스템**:
   - 휴가 승인 시 직원 앱에 푸시 알림
   - 휴가 만료 임박 알림

5. **자동 계산 개선**:
   - 공휴일 제외한 실제 근무일 계산
   - 주말 제외 옵션

---

## 🔗 관련 파일

- **메인 파일**: `/home/user/webapp/index.html`
- **문서**: `/home/user/webapp/VACATION_MANAGEMENT.md` (본 파일)
- **커밋**: `e325459` - feat(vacation): Add comprehensive vacation management

---

## 📞 문의 (Contact)

프로젝트 관련 문의사항이나 버그 리포트는 GitHub Issues를 이용해주세요.

---

**최종 업데이트**: 2026-05-09
**버전**: 1.0.0
**작성자**: GenSpark AI Developer
