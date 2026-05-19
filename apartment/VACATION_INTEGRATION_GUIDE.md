# scan.html 휴가 기능 추가 가이드

## 1단계: 휴가 모달 HTML 추가
`scan.html` 파일의 565번째 줄 (<!-- 🆕 Purchase Inspection Modal -->) **바로 앞**에 `VACATION_MODAL_HTML.txt` 내용 삽입

## 2단계: JavaScript 함수 추가
`scan.html` 파일의 app 객체 안 (showMyPurchases 함수 근처)에 `VACATION_FUNCTIONS_JS.txt` 내용 삽입

## 3단계: 테스트
1. https://bdxi-qr-attendance.vercel.app/scan.html 접속
2. 직원 선택
3. "휴가 관리" 버튼 클릭
4. "새 휴가 신청" 클릭
5. 휴가 정보 입력 후 신청

## 공휴일 필터링 테스트

### 현재 구현된 기능
- ✅ 공휴일 조회 로직 추가됨 (holidays 테이블)
- ✅ 공휴일인 경우 경고 문구 표시
- ✅ 근무시간 체크 (1시간 전 조기출근 경고)
- ✅ 지각 로그 기록 (30분 이상 늦을 경우)

### 테스트 방법
1. Supabase에서 오늘 날짜를 공휴일로 추가:
```sql
INSERT INTO public.holidays (apartment_id, holiday_date, holiday_name, holiday_type)
VALUES ('APT001', '2026-05-07', '테스트 공휴일', 'temporary');
```

2. scan.html에서 출근 버튼 클릭
3. F12 콘솔에서 로그 확인:
```
🎌 오늘 공휴일 확인: [{holiday_name: "테스트 공휴일", holiday_type: "temporary"}]
```

4. 공휴일 경고 팝업 확인:
```
🎌 오늘은 임시공휴일입니다.
공휴일: 테스트 공휴일

그래도 출근하시겠습니까?
사유를 입력해주세요 (취소하려면 빈 칸으로 제출):
```

### 문제 해결
**공휴일 경고가 안 뜨는 경우**:
- [ ] `holidays` 테이블에 오늘 날짜 데이터 있는지 확인
- [ ] `apartment_id`가 일치하는지 확인
- [ ] 콘솔에서 `🎌 오늘 공휴일 확인` 로그 확인
- [ ] 콘솔에 에러 메시지 없는지 확인

**공휴일 데이터가 없는 경우**:
```sql
-- 2026년 5월 공휴일 추가 (테스트용)
INSERT INTO public.holidays (apartment_id, holiday_date, holiday_name, holiday_type)
VALUES 
  ('APT001', '2026-05-05', '어린이날', 'national'),
  ('APT001', '2026-05-06', '석가탄신일', 'national')
ON CONFLICT (apartment_id, holiday_date) DO NOTHING;
```

## 근무시간 필터링 테스트

### 테스트 시나리오 A: 조기 출근
1. 직원의 근무시작 시간이 09:00로 설정되어 있는지 확인
2. 07:30 이전에 출근 시도
3. 예상 결과: "근무 시작 시간보다 1시간 이상 일찍 출근..." 경고 팝업

### 테스트 시나리오 B: 지각
1. 직원의 근무시작 시간이 09:00로 설정되어 있는지 확인
2. 09:30 이후에 출근
3. 예상 결과: 콘솔에 "⚠️ 지각: 30분 늦음" 로그 (출근은 정상 처리)

## 배포 후 확인 사항
1. Vercel 배포 완료 대기 (1~2분)
2. https://bdxi-qr-attendance.vercel.app/scan.html 캐시 새로고침 (Ctrl+Shift+R)
3. 위 테스트 시나리오 실행
4. 콘솔 로그 확인

## 다음 단계
- employee-app.html에도 동일한 휴가 기능 추가
- 관리자 페이지에서 휴가 승인 기능 테스트
- 초과근무/지각 통계 위젯 데이터 확인
