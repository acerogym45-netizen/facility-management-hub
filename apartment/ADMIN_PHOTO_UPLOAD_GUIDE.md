# 관리자 검수 사진 직접 업로드 기능 가이드

**작성일**: 2026-05-08  
**목적**: 검수 QR 코드 제거 및 관리자 직접 사진 업로드 기능 추가

---

## 🎯 기능 개요

### 워크플로우 변경

#### 이전 워크플로우 (QR 코드 기반)
```
1. 관리자가 구매 요청 승인
2. 시스템이 검수 QR 코드 생성
3. 사용자가 물품 수령 시 QR 코드 스캔
4. 사용자가 검수 사진 업로드
```

#### 새 워크플로우 (관리자 직접 업로드) ✅
```
1. 관리자가 구매 요청 승인
2. 관리자가 직접 검수 사진 업로드
3. 완료!
```

**장점**
- ✅ 워크플로우 단순화 (4단계 → 2단계)
- ✅ QR 코드 생성/관리 불필요
- ✅ 즉시 검수 완료 가능
- ✅ 관리자 통제력 향상

---

## ✨ 주요 기능

### 1. 검수 사진 업로드
- **위치**: 구매 요청 상세 모달 (승인된 요청만)
- **버튼**: "사진 추가" (우측 상단)
- **지원 형식**: 이미지 파일 (jpg, png, gif 등)
- **최대 개수**: 10장

### 2. 사진 미리보기
- 파일 선택 시 자동 미리보기
- 각 사진에 번호 표시 (1, 2, 3...)
- 3열 그리드 레이아웃

### 3. 실제 구매 금액 입력
- 선택적 필드
- 예상 금액과 다를 경우 입력
- 구매 요청 레코드에 저장

### 4. 사진 삭제
- 각 사진에 마우스 오버 시 삭제 버튼 표시
- 확인 후 삭제
- Storage 파일 및 DB 레코드 동시 삭제

---

## 📸 사용 방법

### 사진 업로드 절차

#### Step 1: 구매 요청 승인
```
1. 관리자 페이지 접속
2. "🛒 구매 요청" 탭 클릭
3. 승인할 요청 선택
4. [승인] 버튼 클릭
```

#### Step 2: 검수 사진 추가
```
1. 승인된 요청 상세 페이지에서
2. "검수 사진" 섹션 찾기
3. [사진 추가] 버튼 클릭
4. 파일 선택 (최대 10장)
5. 실제 구매 금액 입력 (선택)
6. [업로드] 버튼 클릭
```

#### Step 3: 확인
```
1. "✅ 검수 사진이 성공적으로 업로드되었습니다" 메시지 확인
2. 상세 페이지에서 업로드된 사진 확인
3. Excel/PDF 추출로 검수 조서 생성
```

---

## 🎨 UI 구성

### 승인 전 (Pending 상태)
```
┌─────────────────────────────────────┐
│ 구매 요청 상세                       │
├─────────────────────────────────────┤
│ 기본 정보                            │
│ 구매 사유                            │
│ 물품 목록                            │
│                                     │
│ [승인]  [반려]  [Excel] [PDF] [닫기]│
└─────────────────────────────────────┘
```

### 승인 후 - 사진 없음 (Approved, 사진 0장)
```
┌─────────────────────────────────────┐
│ 구매 요청 상세                       │
├─────────────────────────────────────┤
│ 기본 정보                            │
│ 구매 사유                            │
│ 물품 목록                            │
│                                     │
│ ┌─ 검수 사진 ──────── [사진 추가] ┐│
│ │                                  ││
│ │   📷                             ││
│ │   검수 사진이 없습니다            ││
│ │                                  ││
│ │   [검수 사진 추가]                ││
│ │                                  ││
│ └──────────────────────────────────┘│
│                                     │
│ 승인 완료 (검수 사진 추가 가능)       │
│ [Excel] [PDF] [닫기]                │
└─────────────────────────────────────┘
```

### 승인 후 - 사진 있음 (Approved, 사진 3장)
```
┌─────────────────────────────────────┐
│ 구매 요청 상세                       │
├─────────────────────────────────────┤
│ 기본 정보                            │
│ 구매 사유                            │
│ 물품 목록                            │
│                                     │
│ ┌─ 검수 사진 ──────── [사진 추가] ┐│
│ │ ┌─────┬─────┬─────┐            ││
│ │ │[사진1]│[사진2]│[사진3]│      (×) ││
│ │ │  ❌  │  ❌  │  ❌  │            ││
│ │ └─────┴─────┴─────┘            ││
│ │ 실제 구매 금액: ₩192,500         ││
│ └──────────────────────────────────┘│
│                                     │
│ 승인 완료 (검수 사진 추가 가능)       │
│ [Excel] [PDF] [닫기]                │
└─────────────────────────────────────┘
```

### 사진 업로드 모달
```
┌─────────────────────────────────────┐
│ 📷 검수 사진 추가               × │
├─────────────────────────────────────┤
│                                     │
│ 검수 사진                            │
│ [파일 선택...]                       │
│ 최대 10장까지 업로드 가능합니다       │
│                                     │
│ ┌─ 미리보기 ──────────────────────┐│
│ │ ┌─────┬─────┬─────┐            ││
│ │ │[사진1]│[사진2]│[사진3]│            ││
│ │ │   1  │   2  │   3  │            ││
│ │ └─────┴─────┴─────┘            ││
│ └──────────────────────────────────┘│
│                                     │
│ 실제 구매 금액 (선택)                 │
│ [₩0                              ]  │
│                                     │
├─────────────────────────────────────┤
│     [업로드]        [취소]           │
└─────────────────────────────────────┘
```

---

## 🔧 기술 세부사항

### 파일 저장 구조
```
Supabase Storage: purchase-photos
└── {purchaseRequestId}/
    ├── 1715158272000_0_photo1.jpg
    ├── 1715158272000_1_photo2.jpg
    └── 1715158272000_2_photo3.jpg

파일명 형식: {timestamp}_{index}_{originalName}
```

### 데이터베이스 구조
```sql
-- purchase_photos 테이블
CREATE TABLE purchase_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_request_id UUID REFERENCES purchase_requests(id),
  photo_url TEXT NOT NULL,
  uploaded_by UUID REFERENCES employees(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- purchase_requests 테이블 (actual_amount 컬럼)
ALTER TABLE purchase_requests
ADD COLUMN actual_amount DECIMAL(10,2);
```

### 업로드 프로세스
```javascript
// 1. 파일 읽기
const file = files[i];
const base64 = await readFileAsBase64(file);

// 2. Supabase Storage 업로드
const fileName = `${Date.now()}_${i}_${file.name}`;
const { data, error } = await supabase.storage
  .from('purchase-photos')
  .upload(`${purchaseId}/${fileName}`, file);

// 3. 공개 URL 가져오기
const { data: urlData } = supabase.storage
  .from('purchase-photos')
  .getPublicUrl(`${purchaseId}/${fileName}`);

// 4. DB에 레코드 추가
await supabase
  .from('purchase_photos')
  .insert({
    purchase_request_id: purchaseId,
    photo_url: urlData.publicUrl,
    uploaded_by: currentUser.id
  });
```

### 삭제 프로세스
```javascript
// 1. 사진 정보 조회
const { data: photo } = await supabase
  .from('purchase_photos')
  .select('photo_url')
  .eq('id', photoId)
  .single();

// 2. Storage에서 파일 삭제
const filePath = extractPathFromUrl(photo.photo_url);
await supabase.storage
  .from('purchase-photos')
  .remove([filePath]);

// 3. DB 레코드 삭제
await supabase
  .from('purchase_photos')
  .delete()
  .eq('id', photoId);
```

---

## 📋 주요 함수

### 1. `app.openPhotoUploadModal(purchaseId)`
**목적**: 사진 업로드 모달 열기  
**파라미터**: `purchaseId` (UUID)  
**동작**:
- 현재 구매 요청 ID 저장
- 모달 표시
- 입력 필드 초기화

### 2. `app.closePhotoUploadModal()`
**목적**: 사진 업로드 모달 닫기  
**동작**:
- 모달 숨김
- 현재 ID 초기화

### 3. `app.previewPhotos(event)`
**목적**: 선택한 사진 미리보기  
**파라미터**: `event` (file input change event)  
**동작**:
- 선택된 파일들 읽기 (최대 10개)
- Base64로 변환
- 미리보기 컨테이너에 표시
- 각 사진에 번호 표시

### 4. `app.uploadInspectionPhotos()`
**목적**: 검수 사진 업로드  
**파라미터**: 없음 (전역 변수 사용)  
**동작**:
1. 파일 검증 (개수, 존재 여부)
2. 로딩 표시
3. 각 파일을 순차적으로:
   - Supabase Storage 업로드
   - 공개 URL 가져오기
   - DB에 레코드 추가
4. 실제 구매 금액 업데이트 (입력된 경우)
5. 성공 메시지 표시
6. 모달 닫기 및 상세 페이지 새로고침

**오류 처리**:
- 파일 없음 → 알림
- 10장 초과 → 알림
- 업로드 실패 → 콘솔 로그, 다음 파일 계속
- 전체 실패 → 오류 메시지

### 5. `app.deleteInspectionPhoto(purchaseId, photoId)`
**목적**: 검수 사진 삭제  
**파라미터**: 
- `purchaseId` (UUID)
- `photoId` (UUID)

**동작**:
1. 삭제 확인
2. 사진 정보 조회
3. Storage 파일 삭제
4. DB 레코드 삭제
5. 성공 메시지 표시
6. 상세 페이지 새로고침

---

## ✅ 제거된 기능

### 검수 QR 코드 관련
- ❌ QR 코드 생성 함수 (`generateInspectionQR`)
- ❌ QR 코드 다운로드 버튼
- ❌ QR 링크 복사 버튼
- ❌ "검수 QR 코드" 섹션 전체
- ❌ "검수 대기 중 (물품 수령 후 QR 스캔 필요)" 메시지
- ❌ QRCode.js 라이브러리 의존성 (여전히 다른 곳에서 사용 가능)

### 삭제 이유
- 워크플로우 복잡도 증가
- 사용자 불편 (QR 스캔 필요)
- 관리자 직접 처리가 더 효율적
- QR 코드 관리 오버헤드

---

## 🎯 사용 시나리오

### 시나리오 1: 일반적인 검수
```
1. 직원이 "김밥" 구매 요청 제출
2. 관리자가 승인
3. 직원이 물품 구매 및 관리자에게 전달
4. 관리자가 물품 확인 및 사진 촬영
5. 관리자가 관리 페이지에서 사진 업로드
6. 완료!
```

### 시나리오 2: 실제 금액 다름
```
1. 직원이 "테스트 1 (세트)" 구매 요청 (예상: ₩7,150)
2. 관리자가 승인
3. 직원이 물품 구매 (실제: ₩6,300)
4. 관리자가 사진 업로드 시 실제 금액 ₩6,300 입력
5. 시스템에 실제 금액 저장
6. PDF 추출 시 실제 금액 표시
```

### 시나리오 3: 여러 장 업로드
```
1. 관리자가 물품 검수
2. 앞면, 뒷면, 라벨, 포장, 영수증 등 5장 촬영
3. [사진 추가] 클릭
4. 5장 한 번에 선택
5. 미리보기 확인
6. [업로드] 클릭
7. 모든 사진이 순차적으로 업로드됨
```

### 시나리오 4: 사진 삭제
```
1. 업로드 후 사진이 흐리게 나온 것 발견
2. 해당 사진에 마우스 오버
3. [×] 버튼 클릭
4. 삭제 확인
5. 새로 촬영한 사진 업로드
```

---

## 📊 성능 및 제한사항

### 업로드 속도
| 사진 수 | 예상 시간 | 비고 |
|---------|-----------|------|
| 1장 | 1-2초 | 네트워크에 따라 다름 |
| 3장 | 3-5초 | 순차 업로드 |
| 5장 | 5-8초 | |
| 10장 | 10-15초 | 최대 |

### 파일 크기 제한
- **권장**: 각 파일 5 MB 이하
- **최대**: Supabase 기본 제한 (보통 50 MB)
- **최적화**: 자동 리사이징 없음 (원본 그대로 업로드)

### Storage 용량
- **Supabase Free Tier**: 1 GB
- **예상 사용량**: 사진당 평균 2-3 MB
- **수용 가능 사진 수**: 약 300-500장

---

## 🔒 보안 및 권한

### 업로드 권한
- **제한**: 관리자(admin) 또는 매니저(manager)만 가능
- **검증**: `currentUser.role` 체크
- **Storage RLS**: `purchase-photos` 버킷에 정책 적용 필요

### 삭제 권한
- **제한**: 업로드한 사용자 또는 관리자만 가능
- **검증**: `uploaded_by` 컬럼 확인
- **안전장치**: 삭제 전 확인 메시지

### Storage RLS 정책 (필요 시 적용)
```sql
-- 업로드 권한: 관리자 및 매니저
CREATE POLICY "Admin can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'purchase-photos' AND
  auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- 읽기 권한: 모든 인증된 사용자
CREATE POLICY "Anyone can view photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'purchase-photos');

-- 삭제 권한: 업로더 또는 관리자
CREATE POLICY "Uploader or admin can delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'purchase-photos' AND
  (auth.uid() = owner OR auth.jwt() ->> 'role' = 'admin')
);
```

---

## 🚀 배포 정보

### Git 커밋
```
dfac8c7 - feat(admin): Add inspection photo upload feature for admins
5862ae7 - fix(purchase): Prevent category text truncation in PDF card header
```

### 주요 변경 파일
- `index.html`:
  - 구매 요청 상세 모달 업데이트
  - 사진 업로드 모달 추가
  - 5개 새 함수 추가

### 배포 URL
- **Production**: https://bdxi-qr-attendance.vercel.app/
- **상태**: ✅ 자동 배포 완료

---

## 🧪 테스트 체크리스트

### 기본 기능
- [ ] 승인된 요청에서 "사진 추가" 버튼 표시
- [ ] 미승인 요청에서 사진 섹션 숨김
- [ ] 파일 선택 시 미리보기 표시
- [ ] 10장 제한 동작
- [ ] 업로드 성공 후 사진 표시
- [ ] 실제 금액 입력 및 저장

### 사진 관리
- [ ] 여러 장 동시 업로드
- [ ] 사진 클릭 시 새 탭에서 열림
- [ ] 사진 호버 시 삭제 버튼 표시
- [ ] 사진 삭제 후 목록 업데이트

### 오류 처리
- [ ] 파일 없이 업로드 시 알림
- [ ] 10장 초과 시 알림
- [ ] 네트워크 오류 시 메시지
- [ ] 삭제 확인 취소 시 동작 안 함

### Excel/PDF 추출
- [ ] 사진 있는 요청 Excel 추출
- [ ] 사진 있는 요청 PDF 추출
- [ ] 사진-품목 매칭 정확
- [ ] 실제 금액 표시

---

## 💡 향후 개선 방안

### 단기
1. **이미지 최적화**: 업로드 전 자동 리사이징
2. **진행률 표시**: 업로드 진행 상황 바 추가
3. **드래그 앤 드롭**: 파일 드래그로 업로드

### 중기
1. **사진 편집**: 회전, 크롭 기능
2. **일괄 다운로드**: 모든 사진을 ZIP으로
3. **사진 정렬**: 드래그로 순서 변경

### 장기
1. **OCR 통합**: 영수증 자동 인식
2. **AI 검수**: 이미지 품질 자동 체크
3. **모바일 앱**: 네이티브 카메라 통합

---

## 📞 지원 및 문의

### 문제 발생 시
1. **업로드 실패**
   - 네트워크 연결 확인
   - 파일 크기 확인 (5 MB 이하 권장)
   - 브라우저 콘솔 로그 확인

2. **사진 표시 안 됨**
   - Supabase Storage 버킷 확인
   - RLS 정책 확인
   - 공개 URL 접근 가능 여부 확인

3. **삭제 안 됨**
   - 권한 확인 (업로더 또는 관리자)
   - Storage 파일 존재 여부 확인
   - DB 레코드 존재 여부 확인

---

## 🏆 기능 요약

### ✅ 추가된 기능
- 관리자 직접 검수 사진 업로드
- 사진 미리보기
- 실제 구매 금액 입력
- 사진 삭제 (호버 버튼)
- Empty state UI

### ❌ 제거된 기능
- 검수 QR 코드 생성
- QR 다운로드/복사
- QR 스캔 워크플로우

### 🎯 핵심 가치
- **단순화**: 워크플로우 4단계 → 2단계
- **효율성**: 관리자 직접 통제
- **편의성**: QR 스캔 불필요
- **신속성**: 즉시 검수 완료 가능

---

**✅ 관리자 검수 사진 업로드 기능 완료!**

**📦 Git Commit**: `dfac8c7`  
**🚀 Production URL**: https://bdxi-qr-attendance.vercel.app/  
**📅 배포일**: 2026-05-08

---

*이 문서는 관리자 검수 사진 직접 업로드 기능의 완전한 가이드입니다.*
