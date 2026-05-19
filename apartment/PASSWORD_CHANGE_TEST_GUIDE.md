# 🔐 비밀번호 변경 기능 테스트 가이드

**완료일**: 2026-05-11  
**Git Commit**: `9d0336a`

---

## ✅ 구현 완료 항목

### 1. employee-app.html (직원 출퇴근 앱)
- ✅ 헤더에 비밀번호 변경 버튼 추가 (🔑 아이콘)
- ✅ 비밀번호 변경 모달 추가
- ✅ JavaScript 함수 구현
  - `openPasswordModal()` - 모달 열기
  - `closePasswordModal()` - 모달 닫기
  - `submitPasswordChange()` - 비밀번호 변경 처리

### 2. employee_payroll_dashboard.html (급여명세서 대시보드)
- ✅ 이미 비밀번호 변경 기능 구현되어 있음
- ✅ 헤더에 비밀번호 변경 버튼
- ✅ 비밀번호 변경 모달

---

## 🧪 테스트 시나리오

### 시나리오 1: employee-app.html에서 비밀번호 변경

#### Step 1: 로그인
```
1. employee-app.html 페이지 열기
2. 직원으로 로그인 (이름 + 전화번호 입력)
3. 메인 화면 진입 확인
```

#### Step 2: 비밀번호 변경 모달 열기
```
1. 우측 상단에 🔑 아이콘 버튼 확인
2. 🔑 버튼 클릭
3. 비밀번호 변경 모달 표시 확인
```

#### Step 3: 비밀번호 변경 - 유효성 검증
```
테스트 케이스 1: 빈 필드
- 아무것도 입력하지 않고 "변경" 버튼 클릭
- 예상 결과: "⚠️ 모든 필드를 입력하세요" 토스트 메시지

테스트 케이스 2: 짧은 비밀번호
- 현재 비밀번호: 1234
- 새 비밀번호: 12 (2자리)
- 비밀번호 확인: 12
- 예상 결과: "⚠️ 새 비밀번호는 최소 4자리 이상이어야 합니다"

테스트 케이스 3: 비밀번호 불일치
- 현재 비밀번호: 1234
- 새 비밀번호: abcd1234
- 비밀번호 확인: abcd5678
- 예상 결과: "⚠️ 새 비밀번호가 일치하지 않습니다"

테스트 케이스 4: 잘못된 현재 비밀번호
- 현재 비밀번호: 9999 (잘못된 비밀번호)
- 새 비밀번호: newpass123
- 비밀번호 확인: newpass123
- 예상 결과: "❌ 현재 비밀번호가 일치하지 않습니다"
```

#### Step 4: 비밀번호 변경 성공
```
1. 현재 비밀번호: 1234 (올바른 비밀번호)
2. 새 비밀번호: newpass123
3. 비밀번호 확인: newpass123
4. "변경" 버튼 클릭
5. 예상 결과: "✅ 비밀번호가 성공적으로 변경되었습니다!"
6. 모달 자동 닫힘
```

#### Step 5: 새 비밀번호로 로그인 확인
```
1. 로그아웃
2. 다시 로그인 시도
3. 이름 + 새 비밀번호 (newpass123) 입력
4. 예상 결과: 로그인 성공
```

---

### 시나리오 2: employee_payroll_dashboard.html에서 비밀번호 변경

#### Step 1: 로그인
```
1. employee_payroll_login.html 페이지 열기
2. 이름 + 비밀번호 입력
3. 로그인 후 대시보드 진입
```

#### Step 2: 비밀번호 변경
```
1. 우측 상단 "비밀번호 변경" 버튼 클릭
2. 비밀번호 변경 모달 표시 확인
3. 현재 비밀번호, 새 비밀번호, 확인 입력
4. "변경" 버튼 클릭
5. 예상 결과: "✅ 비밀번호가 성공적으로 변경되었습니다!"
```

---

## 📊 데이터베이스 확인

### Supabase SQL Editor에서 확인

#### 비밀번호 변경 전 상태 확인
```sql
SELECT 
  id,
  name,
  phone,
  login_password,
  password_changed_at,
  force_password_change
FROM employees
WHERE name = '직원이름';
```

**예상 결과**:
```
login_password: 1234 (전화번호 뒷자리)
password_changed_at: NULL
force_password_change: true
```

#### 비밀번호 변경 후 상태 확인
```sql
SELECT 
  id,
  name,
  phone,
  login_password,
  password_changed_at,
  force_password_change
FROM employees
WHERE name = '직원이름';
```

**예상 결과**:
```
login_password: newpass123 (새로 설정한 비밀번호)
password_changed_at: 2026-05-11 10:30:00+00 (변경 시간)
force_password_change: false
```

---

## 🎨 UI 스크린샷 위치

### employee-app.html
```
헤더 위치:
┌─────────────────────────────────────────────┐
│ 📍 서울시 강남구          🔑  로그아웃      │  ← 여기
│ 홍길동                                      │
│ 직원                                        │
└─────────────────────────────────────────────┘
```

### 비밀번호 변경 모달
```
┌─────────────────────────────────────┐
│  🔑 비밀번호 변경               ✕  │
├─────────────────────────────────────┤
│                                     │
│  🔒 현재 비밀번호                   │
│  ┌─────────────────────────────┐   │
│  │ ****************           │   │
│  └─────────────────────────────┘   │
│                                     │
│  🔑 새 비밀번호                     │
│  ┌─────────────────────────────┐   │
│  │ ****************           │   │
│  └─────────────────────────────┘   │
│  최소 4자리 이상 입력하세요         │
│                                     │
│  ✅ 비밀번호 확인                   │
│  ┌─────────────────────────────┐   │
│  │ ****************           │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  [  취소  ]      [  변경  ]        │
└─────────────────────────────────────┘
```

---

## 🔧 문제 해결

### 문제 1: 비밀번호 변경 버튼이 안 보임
```javascript
// 브라우저 콘솔에서 확인
document.getElementById('btn-change-password')

// null이면 페이지 새로고침 후 재확인
// Git에서 최신 버전 pull 받았는지 확인
```

### 문제 2: 비밀번호 변경이 DB에 반영 안 됨
```sql
-- RLS 정책 확인
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'employees';

-- employees 테이블에 UPDATE 권한이 있는지 확인
-- anon 사용자가 UPDATE 가능해야 함
```

### 문제 3: 로그인은 되는데 비밀번호 변경이 안 됨
```javascript
// 브라우저 콘솔에서 Supabase 연결 확인
console.log(app.sb);

// 직원 정보 확인
console.log(app.state.employee);

// login_password 컬럼이 있는지 확인
```

---

## 📝 코드 참조

### employee-app.html 주요 함수

#### 모달 열기
```javascript
openPasswordModal() {
  document.getElementById('password-change-modal').classList.remove('hidden');
  // 입력 필드 초기화
  document.getElementById('current-password-input').value = '';
  document.getElementById('new-password-input').value = '';
  document.getElementById('confirm-password-input').value = '';
}
```

#### 비밀번호 변경 처리
```javascript
async submitPasswordChange() {
  const currentPassword = document.getElementById('current-password-input').value.trim();
  const newPassword = document.getElementById('new-password-input').value.trim();
  const confirmPassword = document.getElementById('confirm-password-input').value.trim();

  // 입력 검증
  if (!currentPassword || !newPassword || !confirmPassword) {
    this.showToast('⚠️ 모든 필드를 입력하세요', 'error');
    return;
  }

  if (newPassword.length < 4) {
    this.showToast('⚠️ 새 비밀번호는 최소 4자리 이상이어야 합니다', 'error');
    return;
  }

  if (newPassword !== confirmPassword) {
    this.showToast('⚠️ 새 비밀번호가 일치하지 않습니다', 'error');
    return;
  }

  // 현재 비밀번호 확인
  const { data: emp, error: fetchError } = await this.sb
    .from('employees')
    .select('login_password')
    .eq('id', this.state.employee.id)
    .single();

  if (emp.login_password !== currentPassword) {
    this.showToast('❌ 현재 비밀번호가 일치하지 않습니다', 'error');
    return;
  }

  // 비밀번호 변경
  await this.sb
    .from('employees')
    .update({
      login_password: newPassword,
      password_changed_at: new Date().toISOString(),
      force_password_change: false
    })
    .eq('id', this.state.employee.id);

  this.showToast('✅ 비밀번호가 성공적으로 변경되었습니다!', 'success');
}
```

---

## ✅ 완료 체크리스트

- [x] employee-app.html에 비밀번호 변경 버튼 추가
- [x] 비밀번호 변경 모달 UI 구현
- [x] JavaScript 함수 구현
- [x] 입력 검증 로직 추가
- [x] Supabase 연동 (UPDATE)
- [x] 토스트 메시지 표시
- [x] Git 커밋 & 푸시
- [ ] employee-app.html에서 실제 테스트
- [ ] employee_payroll_dashboard.html에서 실제 테스트
- [ ] 데이터베이스 업데이트 확인

---

## 🎉 다음 단계

1. **employee-app.html** 페이지 열기
2. 직원으로 로그인
3. 🔑 버튼 클릭하여 비밀번호 변경 테스트
4. 새 비밀번호로 재로그인 확인

**프로젝트 상태**: ✅ 비밀번호 변경 기능 구현 완료!  
**테스트 준비**: ✅ 완료
