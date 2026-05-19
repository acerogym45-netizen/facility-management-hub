# 🚀 BDXI PWA 직원 앱 배포 가이드

## 📋 **배포 완료**

✅ **PWA 직원 앱 v2.0** - GPS 위치 기반 인증 시스템
- 커밋: `53e86be`
- GitHub: https://github.com/acerogym45-netizen/BDXI-QR-attendance
- Vercel: https://bdxi-qr-attendance.vercel.app

---

## 🎯 **핵심 기능**

### **1. GPS 위치 기반 인증 (1km 반경)**
```
✅ 실시간 GPS 추적
✅ Haversine 공식 거리 계산
✅ 정확도 검증 (±100m 이내)
✅ 근무지 범위 자동 감지
```

### **2. PWA 기능**
```
✅ 홈 화면 추가 가능
✅ 오프라인 지원 (Service Worker)
✅ 설치 프롬프트
✅ 네이티브 앱 같은 UX
```

### **3. 출퇴근 기록**
```
✅ GPS 좌표 자동 저장
✅ 거리 및 정확도 기록
✅ 의심 활동 감지 준비
```

---

## 📊 **DB 스키마 업데이트 필요**

### **Step 1: Supabase SQL Editor 실행**

https://supabase.com/dashboard/project/qgpqhtuynxhmgawakjxe

→ **SQL Editor** → **New Query** → 아래 스크립트 복사

### **Step 2: update_gps_system.sql 실행**

```sql
-- ========================================
-- GPS 위치 기반 인증 시스템 v2.0
-- ========================================

-- 1️⃣ apartments 테이블에 GPS 좌표 추가
ALTER TABLE apartments 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS allowed_radius_meters INTEGER DEFAULT 1000;

-- 2️⃣ attendance 테이블에 GPS 정보 추가
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS gps_accuracy FLOAT,
ADD COLUMN IF NOT EXISTS distance_from_workplace FLOAT,
ADD COLUMN IF NOT EXISTS is_suspicious BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS suspicious_reason TEXT;

-- 3️⃣ work_photos 테이블에 GPS 정보 추가
ALTER TABLE work_photos 
ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS gps_accuracy FLOAT;

-- 4️⃣ employees 테이블에 기기 인증 컬럼 추가
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS device_fingerprint TEXT,
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS access_token TEXT UNIQUE;

-- 5️⃣ 기존 단지 데이터에 GPS 좌표 추가
UPDATE apartments SET
  location_lat = 37.2157891,
  location_lng = 127.0528374,
  allowed_radius_meters = 1000
WHERE code = 'BJD001';

UPDATE apartments SET
  location_lat = 37.2889456,
  location_lng = 127.1723845,
  allowed_radius_meters = 1000
WHERE code = 'YDB002';

UPDATE apartments SET
  location_lat = 37.2471234,
  location_lng = 127.0768123,
  allowed_radius_meters = 1000
WHERE code = 'SYT003';

UPDATE apartments SET
  location_lat = 36.9912345,
  location_lng = 127.0856789,
  allowed_radius_meters = 1000
WHERE code = 'PGD004';

-- 6️⃣ 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_attendance_location ON attendance(location_lat, location_lng);
CREATE INDEX IF NOT EXISTS idx_attendance_suspicious ON attendance(is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX IF NOT EXISTS idx_employees_device ON employees(device_fingerprint);

-- 7️⃣ 의심스러운 활동 로그 테이블 생성
CREATE TABLE IF NOT EXISTS suspicious_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES employees(id),
  activity_type TEXT NOT NULL,
  reason TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  distance_diff FLOAT,
  time_diff FLOAT,
  speed_kmh FLOAT,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  is_resolved BOOLEAN DEFAULT FALSE,
  admin_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_suspicious_activities_employee ON suspicious_activities(employee_id);
CREATE INDEX IF NOT EXISTS idx_suspicious_activities_unresolved ON suspicious_activities(is_resolved) WHERE is_resolved = FALSE;

-- 8️⃣ RLS 정책
ALTER TABLE suspicious_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all users to insert suspicious activities"
  ON suspicious_activities FOR INSERT TO authenticated, anon WITH CHECK (true);

CREATE POLICY "Allow all users to view suspicious activities"
  ON suspicious_activities FOR SELECT TO authenticated, anon USING (true);

SELECT '✅ GPS 위치 기반 인증 시스템 v2.0 업데이트 완료!' AS message;
```

### **Step 3: 확인**

```sql
SELECT 
  code,
  name,
  location_lat,
  location_lng,
  allowed_radius_meters
FROM apartments
WHERE location_lat IS NOT NULL
ORDER BY code;
```

**예상 결과:**
```
BJD001 | 봉담자이프라이드시티 | 37.2157891 | 127.0528374 | 1000
YDB002 | 용인동백센트럴       | 37.2889456 | 127.1723845 | 1000
SYT003 | 수원영통자이         | 37.2471234 | 127.0768123 | 1000
PGD004 | 평택고덕국제신도시   | 36.9912345 | 127.0856789 | 1000
```

---

## 📱 **사용 방법**

### **직원 앱 접속**

```
URL: https://bdxi-qr-attendance.vercel.app/employee-app.html
```

### **첫 사용 (1회만)**

1. **앱 접속**
2. **직원 이름 입력** (예: 김철수)
3. **위치 권한 허용** (GPS 필수)
4. **홈 화면에 추가** (선택, 권장)

### **이후 사용**

1. **앱 아이콘 터치** (홈 화면)
2. **자동 로그인** (기기 인식)
3. **GPS 확인** (우측 상단 초록색 점)
4. **출퇴근 버튼 클릭**

---

## 🗺️ **GPS 위치 검증**

### **허용 범위**

```
✅ 모든 단지: 1km (1000m) 반경
✅ GPS 정확도: ±100m 이내
```

### **실제 거리 표시**

```
근무지 범위 내 ✓
📍 거리: 250m / 1000m
🎯 정확도: ±15m
```

```
근무지 범위 밖 ⚠️
📍 거리: 1500m / 1000m
🎯 정확도: ±25m
ℹ️ 출퇴근 기록은 1000m 이내에서만 가능합니다
```

---

## 🛠️ **테스트 절차**

### **1. Vercel 배포 확인**

1-2분 대기 후 접속:
```
https://bdxi-qr-attendance.vercel.app/employee-app.html
```

### **2. 모바일 테스트**

#### **Android**
1. Chrome으로 접속
2. 메뉴 → "홈 화면에 추가"
3. 앱 아이콘 생성 확인

#### **iOS (iPhone/iPad)**
1. Safari로 접속
2. 공유 버튼 → "홈 화면에 추가"
3. 앱 아이콘 생성 확인

### **3. GPS 테스트**

#### **정상 케이스 (단지 내부)**
```
1. 단지 관리사무소 도착
2. 앱 실행
3. "출근" 버튼 클릭
4. 예상: ✅ 출근 기록 완료!
         거리: 50m / 1000m
         정확도: ±8m
```

#### **거리 초과 (단지 외부)**
```
1. 단지 1.5km 밖에서 앱 실행
2. "출근" 버튼 클릭
3. 예상: ❌ 출퇴근 기록은 근무지 1000m 이내에서만 가능합니다.
         현재 거리: 1500m
```

#### **GPS 정확도 낮음 (실내 깊숙이)**
```
1. 지하 주차장에서 앱 실행
2. "출근" 버튼 클릭
3. 예상: ❌ GPS 정확도가 낮습니다 (±180m).
         창문 근처나 야외로 이동해주세요.
```

---

## 🔧 **문제 해결**

### **Q1: GPS 위치를 가져올 수 없습니다**

**해결:**
- 설정 → 앱 권한 → 위치 → 허용
- 야외 또는 창문 근처로 이동
- 비행기 모드 해제

### **Q2: 홈 화면에 추가가 안 됩니다**

**해결:**
- Android: Chrome 브라우저 사용
- iOS: Safari 브라우저 사용
- 시크릿 모드는 지원 안 함

### **Q3: 자동 로그인이 안 됩니다**

**해결:**
- 브라우저 캐시 삭제
- 앱 재설치 (홈 화면 아이콘 삭제 후 재추가)

### **Q4: 거리가 부정확합니다**

**해결:**
- GPS 정확도 확인 (±100m 이내 권장)
- 단지 GPS 좌표 확인 (apartments 테이블)
- Google Maps에서 정확한 좌표 확인 후 DB 업데이트

---

## 📍 **단지 GPS 좌표 업데이트 방법**

### **Step 1: Google Maps에서 정확한 좌표 확인**

1. https://www.google.com/maps 접속
2. 단지 관리사무소 검색
3. 우클릭 → "이 장소는 무엇입니까?"
4. 하단에 좌표 표시 (예: 37.2157891, 127.0528374)

### **Step 2: Supabase에서 좌표 업데이트**

```sql
UPDATE apartments SET
  location_lat = 37.2157891,  -- Google Maps에서 확인한 위도
  location_lng = 127.0528374,  -- Google Maps에서 확인한 경도
  allowed_radius_meters = 1000
WHERE code = 'BJD001';
```

---

## 🎯 **다음 단계 (향후 구현)**

### **Phase 2: 완전한 기능 통합**
- [ ] 업무 사진 업로드 + GPS 메타데이터
- [ ] 구매 요청/검수 기능 (scan.html 통합)
- [ ] Before/After 사진 완전 구현

### **Phase 3: 고급 기능**
- [ ] 푸시 알림 (승인/반려 알림)
- [ ] 관리자 대시보드 지도 뷰
- [ ] 의심 활동 자동 감지 & 플래그

### **Phase 4: 최적화**
- [ ] GPS 배터리 최적화
- [ ] 오프라인 모드 개선
- [ ] 성능 향상

---

## 📊 **시범 운영 설정**

```
✅ 허용 반경: 1km (1000m) - 유연한 설정
✅ GPS 정확도 요구: ±100m 이내
✅ 실시간 위치 추적: watchPosition
✅ 거리 계산: Haversine Formula
✅ 의심 활동 감지: 준비 완료 (테이블 생성됨)
```

---

## 🚀 **배포 상태**

- ✅ **GitHub**: https://github.com/acerogym45-netizen/BDXI-QR-attendance (커밋 53e86be)
- ✅ **Vercel**: https://bdxi-qr-attendance.vercel.app (자동 배포)
- ⚠️ **Supabase**: SQL 스크립트 실행 필요 (위 Step 2 참고)
- ⚠️ **단지 GPS 좌표**: 임시 좌표 사용 중 → Google Maps로 정확한 좌표 확인 후 업데이트 필요

---

**준비 완료! 🎉**

SQL 스크립트 실행 → Vercel 배포 확인 (1-2분) → 모바일 테스트 시작!
