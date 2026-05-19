# 📊 월간 정산서 템플릿 설계

## 📋 정산서 구조

### Sheet 1: 요약 정보
```
┌──────────────────────────────────────────────┐
│ 【 월간 정산서 】                              │
│                                              │
│ 단지명: 카인드원 아파트                        │
│ 정산 기간: 2026년 5월 (2026-05-01 ~ 2026-05-31) │
│ 제출일: 2026-06-01                           │
│ 제출자: 김철수 (단지 관리자)                   │
│ 상태: 제출 완료 / 승인 대기 / 승인 완료 / 반려  │
│                                              │
│ 총 직원 수: 15명                              │
│ 근무 일수: 22일                               │
│ 총 근무 시간: 2,640시간                       │
│ 총 급여 합계: ₩45,000,000                    │
└──────────────────────────────────────────────┘
```

### Sheet 2: 직원별 근태 현황
```
┌────┬────────┬─────┬─────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐
│ No │ 사번   │이름 │부서 │출근일│지각  │결근  │초과  │기본급│수당  │합계  │
│    │        │     │     │      │      │      │근무  │      │      │      │
├────┼────────┼─────┼─────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤
│ 1  │EMP001 │김철수│총무 │  22  │  0   │  0   │ 10h  │3,000K│ 200K │3,200K│
│ 2  │EMP002 │이영희│인사 │  22  │  1   │  0   │  5h  │2,800K│ 100K │2,900K│
│ 3  │EMP003 │박민수│관리 │  21  │  0   │  1   │  0h  │2,500K│   0K │2,500K│
└────┴────────┴─────┴─────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘
```

### Sheet 3: 일별 출퇴근 기록
```
┌────────┬─────────┬─────────┬──────────┬──────────┬────────┬──────┐
│  날짜  │  이름   │  출근   │  퇴근    │ 근무시간 │  상태  │ 비고 │
├────────┼─────────┼─────────┼──────────┼──────────┼────────┼──────┤
│05-01(월)│김철수  │09:00   │18:00     │   8h     │정상    │      │
│05-01(월)│이영희  │09:05   │18:00     │   7.9h   │지각    │5분   │
│05-01(월)│박민수  │  -     │    -     │    -     │결근    │병가  │
└────────┴─────────┴─────────┴──────────┴──────────┴────────┴──────┘
```

### Sheet 4: 업무 실적 (청소/관리)
```
┌────┬─────────┬──────┬──────────┬────────┬──────┬──────┐
│ No │  이름   │ 구역 │   날짜   │ 업무   │시작  │완료  │
├────┼─────────┼──────┼──────────┼────────┼──────┼──────┤
│ 1  │김철수   │헬스장│2026-05-01│청소    │09:00 │11:30 │
│ 2  │김철수   │수영장│2026-05-01│점검    │13:00 │15:00 │
│ 3  │이영희   │로비  │2026-05-01│청소    │09:00 │12:00 │
└────┴─────────┴──────┴──────────┴────────┴──────┴──────┘
```

### Sheet 5: 구매 요청 내역
```
┌────┬─────────┬────────────┬──────┬──────┬────────┬──────┐
│ No │ 신청자  │   품목     │ 수량 │ 금액 │  상태  │ 비고 │
├────┼─────────┼────────────┼──────┼──────┼────────┼──────┤
│ 1  │김철수   │청소용품    │  5   │50,000│승인완료│      │
│ 2  │이영희   │사무용품    │  3   │30,000│승인대기│      │
│ 3  │박민수   │수리부품    │  2   │80,000│반려    │재작성│
└────┴─────────┴────────────┴──────┴──────┴────────┴──────┘
```

### Sheet 6: 휴가 사용 내역
```
┌────┬─────────┬────────┬────────┬──────┬────────┬──────┐
│ No │  이름   │ 시작일 │ 종료일 │ 일수 │  유형  │ 상태 │
├────┼─────────┼────────┼────────┼──────┼────────┼──────┤
│ 1  │김철수   │05-10   │05-11   │  2   │연차    │승인  │
│ 2  │이영희   │05-15   │05-15   │  1   │반차    │승인  │
│ 3  │박민수   │05-20   │05-22   │  3   │병가    │승인  │
└────┴─────────┴────────┴────────┴──────┴────────┴──────┘
```

### Sheet 7: 특이사항 및 메모
```
┌──────────────────────────────────────────────┐
│【특이사항】                                    │
│                                              │
│ 1. 김철수 - 우수사원 선정 (5월)               │
│ 2. 박민수 - 병가 (5/20-22, 진단서 제출)      │
│ 3. 이영희 - 지각 1회 (교통사고)               │
│                                              │
│【관리자 코멘트】                               │
│ 전반적으로 양호한 근무 태도.                  │
│ 청소 품질 개선 필요 (헬스장 구역)             │
│                                              │
│【본사 피드백】(승인 후 작성)                   │
│ (총괄 관리자가 작성)                          │
└──────────────────────────────────────────────┘
```

---

## 📊 자동 집계 데이터 매핑

### 1. 근태 데이터 (attendance 테이블)
```sql
SELECT 
  e.employee_number,
  e.name,
  e.department,
  COUNT(DISTINCT DATE(a.check_in_time)) as work_days,
  COUNT(CASE WHEN a.status = 'late' THEN 1 END) as late_count,
  COUNT(CASE WHEN a.status = 'absent' THEN 1 END) as absent_count,
  SUM(a.overtime_hours) as total_overtime
FROM attendance a
JOIN employees e ON a.employee_id = e.id
WHERE DATE_TRUNC('month', a.check_in_time) = '2026-05-01'
GROUP BY e.id
```

### 2. 업무 기록 (work_records 테이블)
```sql
SELECT 
  e.name,
  l.name as location,
  w.work_date,
  w.work_type,
  w.start_time,
  w.end_time
FROM work_records w
JOIN employees e ON w.employee_id = e.id
JOIN locations l ON w.location_id = l.id
WHERE DATE_TRUNC('month', w.work_date) = '2026-05-01'
ORDER BY w.work_date, e.name
```

### 3. 구매 요청 (purchase_requests 테이블)
```sql
SELECT 
  e.name as requester,
  p.item_name,
  p.quantity,
  p.estimated_price,
  p.status,
  p.notes
FROM purchase_requests p
JOIN employees e ON p.requester_id = e.id
WHERE DATE_TRUNC('month', p.request_date) = '2026-05-01'
ORDER BY p.request_date
```

### 4. 휴가 사용 (vacation_requests 테이블)
```sql
SELECT 
  e.name,
  v.start_date,
  v.end_date,
  v.days,
  v.type,
  v.status
FROM vacation_requests v
JOIN employees e ON v.employee_id = e.id
WHERE DATE_TRUNC('month', v.start_date) = '2026-05-01'
ORDER BY v.start_date
```

---

## 🗄️ 데이터베이스 테이블 추가 필요

### monthly_settlements (월간 정산서 테이블)
```sql
CREATE TABLE monthly_settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  apartment_id UUID REFERENCES apartments(id),
  year_month TEXT NOT NULL, -- '2026-05'
  
  -- 제출 정보
  submitted_by UUID REFERENCES employees(id),
  submitted_at TIMESTAMP WITH TIME ZONE,
  
  -- 파일 정보
  excel_file_url TEXT, -- Supabase Storage URL
  file_name TEXT,
  
  -- 상태 관리
  status TEXT CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
  
  -- 승인/반려 정보
  reviewed_by UUID, -- 마스터 관리자 ID
  reviewed_at TIMESTAMP WITH TIME ZONE,
  review_comment TEXT,
  
  -- 통계 (자동 계산)
  total_employees INTEGER,
  total_work_days INTEGER,
  total_work_hours DECIMAL,
  total_salary DECIMAL,
  
  -- 메타
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_settlements_apartment ON monthly_settlements(apartment_id);
CREATE INDEX idx_settlements_year_month ON monthly_settlements(year_month);
CREATE INDEX idx_settlements_status ON monthly_settlements(status);

-- RLS 정책
ALTER TABLE monthly_settlements ENABLE ROW LEVEL SECURITY;

-- 단지 관리자: 자기 단지 것만 조회/생성/수정
CREATE POLICY "Apartment admins manage own settlements"
ON monthly_settlements
FOR ALL
USING (
  apartment_id IN (
    SELECT apartment_id FROM employees WHERE id = auth.uid()
  )
);

-- 마스터 관리자: 모든 정산서 조회 및 승인/반려
CREATE POLICY "Master admin full access"
ON monthly_settlements
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees 
    WHERE id = auth.uid() AND role = 'master_admin'
  )
);
```

### settlement_logs (정산서 이력 테이블)
```sql
CREATE TABLE settlement_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  settlement_id UUID REFERENCES monthly_settlements(id),
  
  action TEXT, -- 'created', 'submitted', 'approved', 'rejected', 'revised'
  actor_id UUID REFERENCES employees(id),
  actor_name TEXT,
  actor_role TEXT,
  
  comment TEXT,
  previous_status TEXT,
  new_status TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_settlement_logs_settlement ON settlement_logs(settlement_id);
```

---

## 🎨 UI 구성

### index.html (단지 관리자)
```
📊 정산서 관리 탭
├── 이번 달 정산서
│   ├── 자동 집계 통계
│   ├── [정산서 생성] 버튼
│   └── [본사에 제출] 버튼
│
├── 제출 이력
│   └── 월별 정산서 목록
│       ├── 상태 (초안/제출/승인/반려)
│       ├── [다운로드]
│       └── [수정]
│
└── 승인 피드백
    └── 반려 사유 표시
```

### master_dashboard.html (총괄 관리자)
```
💰 급여 관리 탭
├── 정산서 승인 대기
│   ├── 단지별 정산서 목록
│   ├── [다운로드]
│   ├── [승인] 버튼
│   └── [반려] 버튼
│
├── 급여명세서 발급
│   ├── 승인된 정산서 기준
│   ├── PDF 업로드
│   └── [일괄 발급] 버튼
│
└── 발급 이력
    └── 월별 발급 현황
```

---

## 📌 다음 단계

**A. 정산서 자동 생성 구현** (추천!)
- index.html에 "📊 정산서 관리" 탭 추가
- 자동 집계 JavaScript 함수
- Excel 파일 생성 (SheetJS)
- Storage 업로드

**B. 마스터 대시보드에 급여 관리 추가**
- master_dashboard.html 수정
- 정산서 승인/반려 UI
- 급여명세서 발급 기능

**C. 데이터베이스 스키마 생성**
- monthly_settlements 테이블
- settlement_logs 테이블
- RLS 정책

어떤 것부터 시작할까요? 🚀

**추천 순서**: C → A → B
