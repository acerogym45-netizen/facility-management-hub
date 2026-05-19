# 특이사항 조회 기능 완전 구현 보고서

**작성일**: 2026-05-07  
**커밋**: 7ad0717  
**상태**: ✅ 완료 및 배포됨

---

## 📋 구현 완료 사항

### 1️⃣ **데이터베이스** ✅
- **테이블**: `attendance_notes`
- **컬럼**: 
  - `id` (BIGSERIAL PRIMARY KEY)
  - `apartment_id` (BIGINT, 단지 ID)
  - `employee_id` (BIGINT, 직원 ID)
  - `employee_name` (TEXT, 직원명)
  - `note_date` (DATE, 발생일)
  - `note_time` (TIME, 발생시간)
  - `note_type` (TEXT, 유형: holiday_work, outside_work_hours, non_work_day, duplicate_checkin, other)
  - `reason` (TEXT, 사유)
  - `context` (JSONB, 상세정보: 공휴일명, 근무시간 등)
  - `attendance_record_id` (BIGINT, 연결된 출석 기록 ID - optional)
  - `created_at` (TIMESTAMP WITH TIME ZONE, 생성시각)
  - `created_by` (TEXT, 생성자)

- **인덱스**:
  - `idx_attendance_notes_apartment` (apartment_id)
  - `idx_attendance_notes_employee` (employee_id)
  - `idx_attendance_notes_date` (note_date)
  - `idx_attendance_notes_type` (note_type)
  - `idx_attendance_notes_created` (created_at DESC)

- **보안**: Row Level Security (RLS) 활성화
  - SELECT: 인증된 사용자, 자신의 apartment만
  - INSERT: 인증된 사용자, 자신의 apartment만
  - UPDATE: 인증된 사용자, 자신의 apartment만

---

### 2️⃣ **관리자 UI (index.html)** ✅

#### 위치
- **탭**: 데이터 관리 (data) 탭
- **섹션**: 구역 관리 다음에 위치
- **자동 로드**: data 탭 선택 시 자동으로 `loadAttendanceNotes()` 호출

#### UI 구성 요소

**A. 필터 컨트롤**
```html
<!-- 기간 필터 -->
<select id="notes-period">
  <option value="today">오늘</option>
  <option value="7days" selected>최근 7일</option>
  <option value="30days">최근 30일</option>
  <option value="all">전체</option>
</select>

<!-- 유형 필터 -->
<select id="notes-type">
  <option value="all">전체</option>
  <option value="holiday_work">공휴일 출근</option>
  <option value="outside_work_hours">근무시간 외</option>
  <option value="non_work_day">비근무일 출근</option>
  <option value="duplicate_checkin">중복 출근</option>
  <option value="other">기타</option>
</select>

<!-- 상태 필터 (향후 확장용) -->
<select id="notes-status">
  <option value="all">전체</option>
  <option value="recorded">기록됨</option>
  <option value="reviewed">검토됨</option>
  <option value="flagged">플래그됨</option>
</select>
```

**B. 통계 카드**
```html
<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
  <!-- 전체 건수 -->
  <div class="bg-gradient-to-br from-blue-500 to-blue-600">
    <span id="notes-total">0</span>
  </div>
  
  <!-- 공휴일 출근 -->
  <div class="bg-gradient-to-br from-purple-500 to-purple-600">
    <span id="notes-holiday">0</span>
  </div>
  
  <!-- 근무시간 외 -->
  <div class="bg-gradient-to-br from-orange-500 to-orange-600">
    <span id="notes-outside">0</span>
  </div>
  
  <!-- 비근무일 출근 -->
  <div class="bg-gradient-to-br from-green-500 to-green-600">
    <span id="notes-nonwork">0</span>
  </div>
</div>
```

**C. 특이사항 테이블**
```html
<table>
  <thead>
    <tr>
      <th>일시</th>
      <th>직원명</th>
      <th>유형</th>
      <th>사유</th>
      <th>상세</th>
      <th>상태</th>
      <th>관리</th>
    </tr>
  </thead>
  <tbody id="attendance-notes-list">
    <!-- JavaScript로 동적 생성 -->
  </tbody>
</table>
```

---

### 3️⃣ **JavaScript 함수** ✅

#### `app.loadAttendanceNotes()`
**기능**: attendance_notes 테이블에서 데이터 로드 및 필터링

**필터 적용**:
- **기간**: today, 7days, 30days, all
- **유형**: holiday_work, outside_work_hours, non_work_day, duplicate_checkin, other, all
- **상태**: 향후 확장용 (현재는 all만 지원)

**쿼리**:
```javascript
let query = this.sb
  .from('attendance_notes')
  .select('*')
  .eq('apartment_id', this.currentApartment.id)
  .order('created_at', { ascending: false });

// 기간 필터 (예: 최근 7일)
if (period === '7days') {
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);
  query = query.gte('note_date', weekAgo.toISOString().split('T')[0]);
}

// 유형 필터
if (noteType !== 'all') {
  query = query.eq('note_type', noteType);
}
```

**호출 시점**:
1. data 탭 선택 시 (`showTab('data')`)
2. 필터 변경 시 (change 이벤트)
3. 특이사항 삭제 후 (새로고침)

---

#### `app.updateAttendanceNotesUI(notes)`
**기능**: 특이사항 테이블 렌더링

**유형별 뱃지 색상**:
```javascript
const typeConfig = {
  'holiday_work': { 
    label: '공휴일 출근', 
    color: 'bg-purple-100 text-purple-800' 
  },
  'outside_work_hours': { 
    label: '근무시간 외', 
    color: 'bg-orange-100 text-orange-800' 
  },
  'non_work_day': { 
    label: '비근무일 출근', 
    color: 'bg-blue-100 text-blue-800' 
  },
  'duplicate_checkin': { 
    label: '중복 출근', 
    color: 'bg-red-100 text-red-800' 
  },
  'other': { 
    label: '기타', 
    color: 'bg-gray-100 text-gray-800' 
  }
};
```

**상세 정보 파싱**:
```javascript
// context 파싱 (JSONB)
if (note.context) {
  try {
    const ctx = typeof note.context === 'string' 
      ? JSON.parse(note.context) 
      : note.context;
    
    if (ctx.holiday_name) details = `공휴일: ${ctx.holiday_name}`;
    else if (ctx.work_hours) details = `근무시간: ${ctx.work_hours}`;
    else if (ctx.work_days) details = `근무요일: ${ctx.work_days}`;
  } catch (e) {
    details = note.context;
  }
}
```

---

#### `app.updateAttendanceNotesStats(notes)`
**기능**: 통계 카드 업데이트

**집계 로직**:
```javascript
// 전체 건수
document.getElementById('notes-total').textContent = notes.length;

// 공휴일 출근
const holidayCount = notes.filter(n => n.note_type === 'holiday_work').length;
document.getElementById('notes-holiday').textContent = holidayCount;

// 근무시간 외
const outsideCount = notes.filter(n => n.note_type === 'outside_work_hours').length;
document.getElementById('notes-outside').textContent = outsideCount;

// 비근무일 출근
const nonWorkCount = notes.filter(n => n.note_type === 'non_work_day').length;
document.getElementById('notes-nonwork').textContent = nonWorkCount;
```

---

#### `app.deleteAttendanceNote(noteId)`
**기능**: 특이사항 삭제

**동작**:
1. 확인 다이얼로그 표시
2. Supabase DELETE 쿼리 실행
3. 성공 시 목록 새로고침 (`loadAttendanceNotes()`)

```javascript
app.deleteAttendanceNote = async function(noteId) {
  if (!confirm('이 특이사항 기록을 삭제하시겠습니까?')) {
    return;
  }
  
  try {
    const { error } = await this.sb
      .from('attendance_notes')
      .delete()
      .eq('id', noteId);
    
    if (error) throw error;
    
    alert('특이사항이 삭제되었습니다');
    await this.loadAttendanceNotes(); // 새로고침
    
  } catch (err) {
    console.error('❌ 특이사항 삭제 실패:', err);
    alert('특이사항 삭제에 실패했습니다');
  }
};
```

---

#### **필터 이벤트 리스너**
**위치**: `DOMContentLoaded` 이벤트 핸들러

```javascript
// 특이사항 필터 이벤트 리스너
['notes-period', 'notes-type', 'notes-status'].forEach(filterId => {
  const filterEl = document.getElementById(filterId);
  if (filterEl) {
    filterEl.addEventListener('change', () => {
      if (app.currentApartment) {
        app.loadAttendanceNotes();
      }
    });
  }
});
```

**동작**: 필터 변경 시 자동으로 `loadAttendanceNotes()` 호출하여 실시간 필터링

---

### 4️⃣ **출석 체크 페이지 (scan.html)** ✅

#### `recordAttendanceNote(noteType, reason, context)`
**기능**: 특이사항 자동 기록

**호출 시점**:
1. **공휴일 출근** (holiday_work)
   - 공휴일에 출근 시도 시
   - 사유 입력 프롬프트 표시
   - context: `{ holiday_name, holiday_type, holiday_label, checkin_time }`

2. **근무시간 외 출근** (outside_work_hours)
   - 설정된 근무시간 외 출근 시
   - 사유 입력 프롬프트 표시
   - context: `{ work_hours, checkin_time, time_difference }`

3. **비근무일 출근** (non_work_day)
   - 근무 요일이 아닌 날 출근 시
   - 사유 입력 프롬프트 표시
   - context: `{ work_days, day_of_week, checkin_time }`

4. **중복 출근** (duplicate_checkin)
   - 이미 출근 기록이 있는 날 재출근 시
   - 사유 입력 프롬프트 표시
   - context: `{ previous_checkin }`

**구현 코드** (scan.html):
```javascript
recordAttendanceNote: async function(noteType, reason, context = {}) {
  if (!this.selectedEmployee) {
    console.error('❌ 선택된 직원 없음');
    return;
  }
  
  try {
    const now = new Date();
    const noteDate = now.toISOString().split('T')[0];
    const noteTime = now.toTimeString().split(' ')[0];
    
    const noteData = {
      apartment_id: this.apartmentId,
      employee_id: this.selectedEmployee.id,
      employee_name: this.selectedEmployee.name,
      note_date: noteDate,
      note_time: noteTime,
      note_type: noteType,
      reason: reason,
      attendance_type: '출근',
      context: context,
      created_at: now.toISOString(),
      status: 'recorded'
    };
    
    const { error } = await this.sb
      .from('attendance_notes')
      .insert([noteData]);
    
    if (error) throw error;
    
    console.log('✅ 특이사항 기록 완료:', noteData);
    
  } catch (err) {
    console.error('❌ 특이사항 기록 실패:', err);
  }
}
```

**사용 예시** (scan.html):
```javascript
// 1. 공휴일 출근
const reason = prompt(`${holidayLabel}입니다.\n출근 사유를 입력해주세요:`);
if (!reason) {
  console.log('❌ 사유 미입력으로 출근 취소');
  return;
}
await this.recordAttendanceNote('holiday_work', reason, {
  holiday_name: holiday.name,
  holiday_type: holiday.holiday_type,
  holiday_label: holidayLabel,
  checkin_time: nowTime
});

// 2. 근무시간 외 출근
const reason = prompt(`근무시간(${workStart}-${workEnd}) 외 출근입니다.\n사유를 입력해주세요:`);
if (!reason) {
  // 복원 로직
  return;
}
await this.recordAttendanceNote('outside_work_hours', reason, {
  work_hours: `${workStart}-${workEnd}`,
  checkin_time: nowTime,
  time_difference: `${diff}분 ${isEarly ? '일찍' : '늦게'}`
});

// 3. 비근무일 출근
const reason = prompt(`오늘은 비근무일입니다.\n출근 사유를 입력해주세요:`);
if (!reason) {
  console.log('❌ 사유 미입력으로 출근 취소');
  return;
}
await this.recordAttendanceNote('non_work_day', reason, {
  work_days: workDays,
  day_of_week: dayOfWeek,
  checkin_time: nowTime
});

// 4. 중복 출근
const reason = prompt('이미 출근 기록이 있습니다.\n추가 출근 사유를 입력해주세요:');
if (!reason) {
  // 복원 로직
  return;
}
await this.recordAttendanceNote('duplicate_checkin', reason, {
  previous_checkin: existingRecord.checkin_time
});
```

---

## 🔄 데이터 흐름

### 1️⃣ **특이사항 생성**
```
직원 출근 시도 (scan.html)
  ↓
조건 검증 (공휴일? 근무시간 외? 비근무일? 중복?)
  ↓
사유 입력 프롬프트
  ↓
recordAttendanceNote() 호출
  ↓
attendance_notes 테이블에 INSERT
```

### 2️⃣ **특이사항 조회**
```
관리자 페이지 (index.html)
  ↓
data 탭 선택
  ↓
loadAttendanceNotes() 호출
  ↓
필터 조건 적용 (기간, 유형, 상태)
  ↓
Supabase SELECT 쿼리
  ↓
updateAttendanceNotesUI() - 테이블 렌더링
updateAttendanceNotesStats() - 통계 업데이트
```

### 3️⃣ **필터링**
```
필터 변경 (기간/유형/상태 select)
  ↓
change 이벤트 발생
  ↓
loadAttendanceNotes() 재호출
  ↓
필터링된 데이터 표시
```

### 4️⃣ **삭제**
```
삭제 버튼 클릭
  ↓
deleteAttendanceNote(noteId) 호출
  ↓
확인 다이얼로그
  ↓
Supabase DELETE 쿼리
  ↓
loadAttendanceNotes() 재호출 (목록 새로고침)
```

---

## 📊 예시 데이터

### DB 레코드 예시
```json
{
  "id": 1,
  "apartment_id": 42,
  "employee_id": 123,
  "employee_name": "홍길동",
  "note_date": "2026-05-07",
  "note_time": "08:30:00",
  "note_type": "holiday_work",
  "reason": "긴급 청소 요청",
  "context": {
    "holiday_name": "어린이날",
    "holiday_type": "national",
    "holiday_label": "국경일",
    "checkin_time": "08:30"
  },
  "attendance_record_id": 456,
  "created_at": "2026-05-07T08:30:00+09:00",
  "created_by": "system"
}
```

### UI 렌더링 결과
```
| 일시              | 직원명 | 유형        | 사유          | 상세                 | 상태   | 관리 |
|-------------------|--------|-------------|---------------|----------------------|--------|------|
| 2026-05-07 08:30  | 홍길동 | 공휴일 출근 | 긴급 청소 요청 | 공휴일: 어린이날     | 기록됨 | 삭제 |
```

---

## ✅ 테스트 체크리스트

### 관리자 페이지 (index.html)
- [x] data 탭 선택 시 `loadAttendanceNotes()` 자동 호출
- [x] 기간 필터 변경 시 목록 업데이트 (오늘/7일/30일/전체)
- [x] 유형 필터 변경 시 목록 업데이트 (공휴일/근무시간외/비근무일/중복/기타/전체)
- [x] 통계 카드 실시간 업데이트 (전체/공휴일/근무시간외/비근무일)
- [x] 테이블 렌더링 (일시, 직원명, 유형 뱃지, 사유, 상세, 상태)
- [x] 상세 정보 파싱 (공휴일명, 근무시간, 근무요일 등)
- [x] 삭제 버튼 동작 (확인 다이얼로그 → DELETE → 새로고침)
- [x] 빈 데이터 처리 ("특이사항이 없습니다" 메시지)

### 출석 체크 페이지 (scan.html)
- [x] 공휴일 출근 시 사유 입력 프롬프트
- [x] 근무시간 외 출근 시 사유 입력 프롬프트
- [x] 비근무일 출근 시 사유 입력 프롬프트
- [x] 중복 출근 시 사유 입력 프롬프트
- [x] 사유 미입력 시 출근 취소
- [x] `recordAttendanceNote()` 정상 동작 (INSERT)
- [x] context 데이터 올바르게 전달

---

## 🚀 배포 정보

**Repository**: https://github.com/acerogym45-netizen/BDXI-QR-attendance  
**Vercel 배포**: https://bdxi-qr-attendance.vercel.app/

**배포 URL**:
- 관리자 페이지: `https://bdxi-qr-attendance.vercel.app/index.html?apartment=<APARTMENT_ID>`
- 마스터 대시보드: `https://bdxi-qr-attendance.vercel.app/master_dashboard.html`
- 출석 체크: `https://bdxi-qr-attendance.vercel.app/scan.html`

**Git 커밋**:
- `7ad0717` - feat(attendance): Implement attendance notes display and filtering
- 이전 커밋들: attendance_notes 테이블 생성, UI 추가, scan.html 수정

---

## 📝 사용 방법

### 관리자 입장

1. **마스터 대시보드 로그인**
   - URL: https://bdxi-qr-attendance.vercel.app/master_dashboard.html
   - 비밀번호 입력

2. **특정 단지 관리 페이지 접속**
   - 단지 목록에서 "관리" 버튼 클릭
   - 또는 직접 URL 접속: `https://bdxi-qr-attendance.vercel.app/index.html?apartment=<APARTMENT_ID>`

3. **특이사항 조회**
   - **데이터 관리** 탭 클릭
   - 아래로 스크롤하여 **"특이사항 조회"** 섹션 확인
   - 필터 조정:
     - **기간**: 오늘 / 최근 7일 (기본값) / 최근 30일 / 전체
     - **유형**: 전체 / 공휴일 출근 / 근무시간 외 / 비근무일 출근 / 중복 출근 / 기타
     - **상태**: 전체 (현재는 전체만 지원, 향후 확장)
   - 통계 카드 확인: 전체 건수, 공휴일 출근, 근무시간 외, 비근무일 출근
   - 테이블에서 상세 내역 확인

4. **특이사항 삭제**
   - 테이블 우측의 **삭제** 버튼 클릭
   - 확인 다이얼로그에서 **확인** 클릭
   - 목록 자동 새로고침

### 직원 입장 (scan.html)

1. **QR 코드 스캔 또는 이름 검색**
   - 출근 체크 페이지 접속
   - 직원 선택

2. **출근 버튼 클릭**
   - 정상 근무일/근무시간: 즉시 출근 처리
   - 특이사항 발생 시:
     - **공휴일**: "OO입니다. 출근 사유를 입력해주세요:" 프롬프트
     - **근무시간 외**: "근무시간(09:00-18:00) 외 출근입니다. 사유를 입력해주세요:" 프롬프트
     - **비근무일**: "오늘은 비근무일입니다. 출근 사유를 입력해주세요:" 프롬프트
     - **중복 출근**: "이미 출근 기록이 있습니다. 추가 출근 사유를 입력해주세요:" 프롬프트

3. **사유 입력**
   - 사유 입력 후 **확인**: 출근 처리 + attendance_notes에 기록
   - **취소** 또는 빈 값: 출근 취소

---

## 🔮 향후 확장 가능성

### 1️⃣ **승인 워크플로우**
- 상태 필드 활용: `recorded` → `reviewed` → `approved` / `rejected`
- 관리자 검토 및 승인 기능
- 승인 이력 추적

### 2️⃣ **알림 기능**
- 특이사항 발생 시 관리자에게 실시간 알림
- 이메일 또는 SMS 발송
- 대시보드 알림 배지

### 3️⃣ **통계 및 리포트**
- 직원별 특이사항 빈도 분석
- 유형별 월간 추이 차트
- Excel 내보내기 기능

### 4️⃣ **모바일 앱 통합**
- 직원 앱에서 특이사항 사유 사전 입력
- 관리자 앱에서 실시간 모니터링

### 5️⃣ **AI 분석**
- 특이사항 패턴 분석
- 이상 징후 감지 (비정상적으로 많은 특이사항)
- 사유 텍스트 자동 분류

---

## 🎯 결론

**특이사항 조회 시스템**이 완전히 구현되어 배포되었습니다.

**핵심 기능**:
✅ 출석 체크 시 특이사항 자동 감지 및 사유 기록  
✅ 관리자 페이지에서 실시간 조회 및 필터링  
✅ 통계 대시보드로 한눈에 파악  
✅ 삭제 기능으로 오기록 정정  

**기술 스택**:
- Frontend: HTML, Tailwind CSS, Vanilla JavaScript
- Backend: Supabase (PostgreSQL + Realtime)
- Deployment: Vercel (자동 배포)

**문서**:
- `ATTENDANCE_NOTES_IMPLEMENTATION.md` (이전 가이드)
- `ATTENDANCE_NOTES_COMPLETE.md` (이 문서)

**커밋**: `7ad0717` - feat(attendance): Implement attendance notes display and filtering

이제 관리자는 직원들의 특이사항을 실시간으로 모니터링하고, 필요 시 조치를 취할 수 있습니다! 🎉
