# 📊 scan.html vs employee-app.html 기능 비교 분석

## 🔍 분석 일자: 2026-05-08

---

## 📈 기능 통계

| 기능 | scan.html | employee-app.html | 차이 |
|------|-----------|-------------------|------|
| **출퇴근 기능** | ✅ 10개 참조 | ✅ 5개 참조 | scan.html이 더 상세 |
| **휴가 신청/관리** | ✅ 6개 참조 | ❌ 0개 | **scan.html만 있음** |
| **구매 요청** | ✅ 55개 참조 | ✅ 65개 참조 | 둘 다 있음 |
| **특이사항 기록** | ✅ 5개 참조 | ❌ 0개 | **scan.html만 있음** |
| **공휴일 체크** | ✅ 16개 참조 | ❌ 0개 | **scan.html만 있음** |
| **근무시간 검증** | ✅ 10개 참조 | ❌ 0개 | **scan.html만 있음** |

---

## 🚨 scan.html에만 있는 기능 (employee-app.html에 추가 필요)

### 1️⃣ 휴가 관리 시스템 ⭐ **중요**
```javascript
// scan.html에 있음
- 휴가 신청 버튼
- 휴가 조회 기능
- 대기 중인 휴가 개수 뱃지
- 휴가 승인/반려 내역 조회
```

**필요 작업:**
- employee-app.html에 휴가 관리 UI 추가
- 휴가 신청 모달 추가
- 휴가 내역 조회 기능 추가

---

### 2️⃣ 특이사항 자동 기록 시스템 ⭐⭐ **매우 중요**
```javascript
// scan.html에만 구현됨
✅ recordAttendanceNote(noteType, reason)
✅ 공휴일 출근 감지 및 사유 입력
✅ 근무시간 외 출근 감지 및 사유 입력
✅ 비근무일 출근 감지 및 사유 입력
✅ 중복 출근 감지 및 사유 입력
```

**employee-app.html 상태:**
```
❌ recordAttendanceNote 함수 없음
❌ 특이사항 감지 로직 없음
❌ 사유 입력 프롬프트 없음
```

**필요 작업:**
- recordAttendanceNote 함수 추가
- 모든 특이사항 감지 로직 복사
- attendance_notes 테이블 연동

---

### 3️⃣ 공휴일 체크 시스템 ⭐
```javascript
// scan.html에 있음
✅ holidays 테이블 조회
✅ 오늘이 공휴일인지 확인
✅ 공휴일 유형 표시 (법정공휴일, 대체공휴일, 임시공휴일)
✅ 공휴일 출근 시 경고 및 사유 입력
```

**employee-app.html 상태:**
```
❌ holidays 테이블 조회 없음
❌ 공휴일 체크 로직 없음
```

**필요 작업:**
- 공휴일 조회 쿼리 추가
- 공휴일 감지 로직 추가
- 공휴일 출근 경고 추가

---

### 4️⃣ 근무시간 검증 시스템 ⭐
```javascript
// scan.html에 있음
✅ work_start_time, work_end_time 확인
✅ 현재 시각이 근무시간 내인지 검증
✅ 근무시간 외 출근 시 경고 및 사유 입력
✅ 지각 감지 (10분 이상)
✅ 조기 출근 감지
```

**employee-app.html 상태:**
```
❌ 근무시간 검증 없음
❌ 지각/조기출근 감지 없음
```

**필요 작업:**
- 근무시간 검증 로직 추가
- 지각/조기출근 경고 추가
- 시간 차이 계산 로직 추가

---

### 5️⃣ 비근무일 체크 시스템 ⭐
```javascript
// scan.html에 있음
✅ work_days 확인 (월, 화, 수, 목, 금)
✅ 오늘이 근무일인지 검증
✅ 비근무일 출근 시 경고 및 사유 입력
```

**employee-app.html 상태:**
```
❌ work_days 검증 없음
❌ 비근무일 체크 없음
```

**필요 작업:**
- work_days 검증 로직 추가
- 비근무일 경고 추가

---

### 6️⃣ 중복 출근 방지 시스템 ⭐
```javascript
// scan.html에 있음
✅ 오늘 이미 출근했는지 확인
✅ 중복 출근 시 경고
✅ 사유 입력 후 허용
```

**employee-app.html 상태:**
```
❌ 중복 출근 체크 없음
```

**필요 작업:**
- 중복 출근 체크 로직 추가
- 사유 입력 프롬프트 추가

---

### 7️⃣ 미완료 퇴근 차단 시스템 ⭐
```javascript
// scan.html에 있음
✅ 출근 시 이전 퇴근 완료 여부 확인
✅ 미완료 퇴근 있으면 출근 차단
✅ 오류 안내 메시지
```

**employee-app.html 상태:**
```
❌ 미완료 퇴근 체크 없음
```

**필요 작업:**
- 미완료 퇴근 검증 로직 추가
- 차단 메시지 추가

---

## 🔄 employee-app.html에만 있는 기능 (scan.html에 추가 필요)

### (분석 중...)

현재까지 분석 결과:
- **employee-app.html이 scan.html보다 더 적은 기능을 가지고 있음**
- **대부분의 검증 로직이 scan.html에만 구현됨**

---

## 📋 통합 필요 작업 리스트

### 🔴 우선순위 1: 필수 보안 기능
1. **특이사항 기록 시스템** → employee-app.html에 추가
   - recordAttendanceNote 함수
   - 모든 감지 로직
   - 사유 입력 프롬프트

2. **공휴일 체크** → employee-app.html에 추가
   - holidays 테이블 조회
   - 공휴일 감지
   - 경고 메시지

3. **근무시간 검증** → employee-app.html에 추가
   - 근무시간 체크
   - 지각/조기출근 감지

### 🟡 우선순위 2: 중요 기능
4. **비근무일 체크** → employee-app.html에 추가
5. **중복 출근 방지** → employee-app.html에 추가
6. **미완료 퇴근 차단** → employee-app.html에 추가

### 🟢 우선순위 3: 편의 기능
7. **휴가 관리 시스템** → employee-app.html에 추가
   - 휴가 신청 UI
   - 휴가 조회 기능

---

## 🎯 권장 통합 방법

### 방법 1: scan.html 코드를 employee-app.html로 복사 ⭐ **추천**
```
1. recordAttendance 함수 전체 교체
2. 모든 검증 로직 포함
3. recordAttendanceNote 함수 추가
4. UI 알림 메시지 추가
```

### 방법 2: 공통 모듈 분리
```
1. attendance-validation.js 생성
2. 모든 검증 로직을 모듈로 분리
3. scan.html, employee-app.html에서 import
```

---

## 📊 코드 복사 체크리스트

### scan.html → employee-app.html 복사할 함수

```javascript
☐ recordAttendanceNote(noteType, reason)
☐ 공휴일 체크 로직 (lines 1164-1208)
☐ 근무시간 체크 로직 (lines 1210-1307)
☐ 지각 체크 로직 (lines 1309-1330)
☐ 중복 출근 체크 (lines 1332-1365)
☐ 비근무일 체크 (lines 1367-1390)
☐ 미완료 퇴근 차단 (lines 1392-1418)
☐ 휴무일 조회 (lines 1420-1450)
```

---

## 🧪 테스트 계획

### employee-app.html 통합 후 테스트

1. **공휴일 출근 테스트**
   ```
   - 공휴일에 employee-app.html 접속
   - 출근 버튼 클릭
   - 경고 메시지 확인
   - 사유 입력
   - attendance_notes 저장 확인
   ```

2. **근무시간 외 테스트**
   ```
   - 22:00에 employee-app.html 접속
   - 출근 버튼 클릭
   - 근무시간 외 경고 확인
   - 사유 입력
   - 저장 확인
   ```

3. **중복 출근 테스트**
   ```
   - 오전에 출근 기록 생성
   - 오후에 다시 출근 시도
   - 중복 출근 경고 확인
   - 사유 입력 후 허용 확인
   ```

---

## 🔍 추가 발견 사항

### scan.html 특징
- ✅ QR 코드 기반 (location 파라미터 필요)
- ✅ URL: `scan.html?location=XXX&apt=YYY`
- ✅ 모든 보안 검증 로직 구현됨
- ✅ 특이사항 자동 기록
- ✅ 관리자 페이지와 완전 연동

### employee-app.html 특징
- ✅ 직원 로그인 기반
- ✅ URL: `employee-app.html`
- ❌ 보안 검증 로직 부족
- ❌ 특이사항 기록 없음
- ⚠️ 기본 출퇴근 기능만 있음

---

## 💡 결론

### 현재 상태
- **scan.html**: 완전한 기능 ✅
- **employee-app.html**: 기본 기능만 ❌

### 해야 할 일
1. ⚠️ **긴급**: employee-app.html에 모든 검증 로직 추가
2. ⚠️ **중요**: 두 파일의 recordAttendance 함수 동기화
3. ⚠️ **권장**: 공통 모듈로 분리하여 중복 코드 제거

### 예상 작업 시간
- 기능 복사 및 통합: **2-3시간**
- 테스트 및 검증: **1-2시간**
- **총 예상 시간: 3-5시간**

---

## 📝 다음 단계

### 1단계: 백업
```bash
cp employee-app.html employee-app.html.backup
```

### 2단계: 기능 복사
- scan.html의 recordAttendance 함수 전체 복사
- recordAttendanceNote 함수 추가
- 모든 검증 로직 추가

### 3단계: 테스트
- 모든 시나리오 테스트
- 관리자 페이지에서 특이사항 확인

### 4단계: 배포
- Git 커밋
- Vercel 자동 배포
- 프로덕션 테스트

---

## 🎯 최종 목표

**두 파일의 기능을 완전히 동기화하여 어느 페이지에서 출퇴근하든 동일한 보안과 기록이 유지되도록!**

---

*분석 완료: 2026-05-08*  
*분석자: Claude*  
*다음 작업: employee-app.html 기능 통합*
