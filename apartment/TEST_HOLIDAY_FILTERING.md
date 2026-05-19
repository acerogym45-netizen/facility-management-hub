# 공휴일 및 근무시간 필터링 테스트 가이드

## 🎌 공휴일 필터링 테스트

### 사전 준비
1. Supabase SQL Editor에서 `holidays` 테이블 데이터 확인
```sql
SELECT * FROM public.holidays 
WHERE apartment_id = 'APT001'  -- 테스트 단지 ID
ORDER BY holiday_date;
```

2. 테스트용 공휴일 추가 (2026년 5월)
```sql
INSERT INTO public.holidays (apartment_id, holiday_date, holiday_name, holiday_type)
VALUES 
  ('APT001', '2026-05-05', '어린이날', 'national'),
  ('APT001', '2026-05-06', '석가탄신일', 'national')
ON CONFLICT (apartment_id, holiday_date) DO NOTHING;
```

### 테스트 시나리오

#### 시나리오 A: 공휴일에 퇴근 미기록 확인
**목적**: 공휴일에 퇴근 기록이 없어도 차단되지 않는지 확인

**절차**:
1. https://bdxi-qr-attendance.vercel.app/scan.html 접속
2. 테스트 단지 + 테스트1 직원 선택
3. 개발자 도구(F12) 콘솔 열기
4. 출근 버튼 클릭
5. 콘솔 로그 확인:
```
🎌 공휴일 목록: [{holiday_date: "2026-05-05", ...}, ...]
🔍 필터링 결과: {원본: X건, 근무요일_필터: Y건, 중복제거: Z건}
```

**예상 결과**:
- 공휴일이 목록에 표시됨
- 공휴일이 차단 제외됨
- 3건 미만이면 출근 허용

**실패 원인 분석**:
- ❌ 공휴일 목록이 `[]` 또는 `null`로 표시 → `holidays` 테이블에 데이터 없음
- ❌ `apartment_id` 필터가 잘못됨 → 단지 ID 확인 필요
- ❌ 날짜 비교 로직 오류 → `toDateString()` 비교 검증 필요

### 디버깅 코드 추가
scan.html 1178번째 줄 이후에 추가:
```javascript
console.log('🎌 공휴일 목록:', holidays);
console.log('🔍 공휴일 개수:', holidays?.length || 0);
console.log('🏢 현재 아파트 ID:', this.state.aptId);
if (holidays && holidays.length > 0) {
  console.log('📅 첫 번째 공휴일:', holidays[0]);
}
```

---

## 🕐 근무시간 필터링 테스트

### 개요
직원의 `work_start_time`과 `work_end_time`을 기준으로 근무시간 외 출퇴근 기록을 필터링합니다.

### 구현 필요사항

#### 1. 출근 시간 검증
**로직**: 
- `work_start_time` 이전 출근 → 조기출근 (정상 처리)
- `work_start_time` + 10분 이후 출근 → 지각 (경고 표시)

#### 2. 퇴근 시간 검증
**로직**:
- `work_end_time` 이후 퇴근 → 정상 또는 초과근무
- `work_end_time` 이전 퇴근 + 근무시간 8시간 미만 → 조퇴

#### 3. 필터링 적용 지점
- `scan.html`: 출근 차단 검증 단계에서 근무시간 외 기록 제외
- `index.html`: 근태 관리 탭에서 지각/조퇴 통계 표시

### 테스트 시나리오

#### 시나리오 B: 근무시간 설정 확인
**절차**:
1. 관리자 페이지 → 데이터 관리 → 직원 관리
2. 테스트1 직원 수정
3. 근무시간 확인: `09:00 - 18:00`

#### 시나리오 C: 지각 기록 생성
**절차**:
1. Supabase에서 테스트 데이터 생성
```sql
INSERT INTO attendance_records (employee_id, employee_name, apartment_id, attendance_type, scan_time)
VALUES 
  ('EMP001', '테스트1', 'APT001', '출근', '2026-05-07T09:30:00+09:00'),
  ('EMP001', '테스트1', 'APT001', '퇴근', '2026-05-07T18:00:00+09:00');
```
2. 근태 관리 탭 → 지각/결근 현황 확인
3. 테스트1이 `+30분` 지각으로 표시되는지 확인

#### 시나리오 D: 초과근무 기록 생성
**절차**:
1. Supabase에서 테스트 데이터 생성
```sql
INSERT INTO attendance_records (employee_id, employee_name, apartment_id, attendance_type, scan_time)
VALUES 
  ('EMP001', '테스트1', 'APT001', '출근', '2026-05-08T09:00:00+09:00'),
  ('EMP001', '테스트1', 'APT001', '퇴근', '2026-05-08T20:00:00+09:00');
```
2. 근태 관리 탭 → 초과근무 현황 확인
3. 테스트1이 `+3.0h` 초과근무로 표시되는지 확인

---

## 🔧 문제 해결 체크리스트

### 공휴일 필터링이 작동하지 않는 경우
- [ ] `holidays` 테이블에 데이터가 있는지 확인
- [ ] `apartment_id`가 올바른지 확인
- [ ] 날짜 형식이 `YYYY-MM-DD`인지 확인
- [ ] 콘솔에서 공휴일 목록이 로드되는지 확인

### 근무시간 필터링이 작동하지 않는 경우
- [ ] 직원의 `work_start_time`, `work_end_time`이 설정되어 있는지 확인
- [ ] 시간대(timezone)가 올바른지 확인 (KST +09:00)
- [ ] 근태 기록의 `scan_time` 형식이 올바른지 확인

---

## 📊 검증 완료 기준

### 공휴일 필터링
✅ 공휴일에 퇴근 미기록이 있어도 출근 차단되지 않음  
✅ 콘솔에서 공휴일 목록이 정상적으로 로드됨  
✅ 공휴일이 차단 제외 로그에 표시됨  

### 근무시간 필터링
✅ 지각 기록이 근태 관리 탭에 표시됨  
✅ 초과근무 기록이 근태 관리 탭에 표시됨  
✅ 조퇴 기록이 근태 관리 탭에 표시됨  

---

## 다음 단계
1. Supabase에서 `UPDATE_VACATIONS_APPROVAL.sql` 실행
2. 테스트용 휴가 신청 데이터 생성
3. 휴가 승인/거부 기능 테스트
4. 전체 시스템 통합 테스트
