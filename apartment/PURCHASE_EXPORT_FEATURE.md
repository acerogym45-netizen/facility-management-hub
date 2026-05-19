# 구매 요청 Excel/PDF 추출 기능 구현 완료 📊

## 📋 개요

구매 요청 상세보기 모달에서 각 구매 건을 **Excel** 또는 **PDF** 파일로 추출할 수 있는 기능을 구현했습니다.

## ✨ 주요 기능

### 1️⃣ Excel 추출 (`.xlsx`)

**포함 내용:**
- ✅ **기본 정보**
  - 요청일
  - 상태 (승인 대기/승인됨/반려됨/검수 완료)
  - 요청자 (이름 + 역할)
  - 총 금액

- ✅ **구매 사유**
  - 전체 사유 텍스트

- ✅ **물품 목록**
  - 물품명
  - 카테고리
  - 수량
  - 단가
  - 금액 (수량 × 단가)

- ✅ **검수 사진 정보** (물품-이미지 매칭)
  - 번호
  - 물품명
  - 수량
  - 단가
  - 총액
  - 사진 URL

- ✅ **승인/반려 정보**
  - 승인자 및 승인 시각 (승인된 경우)
  - 반려 사유 (반려된 경우)

**파일명 형식:**
```
구매요청_[요청자명]_YYYY-MM-DD.xlsx
예: 구매요청_김철수_2026-05-08.xlsx
```

### 2️⃣ PDF 추출 (`.pdf`)

**포함 내용 및 레이아웃:**

**📄 1페이지 - 기본 정보 및 물품 목록**
```
┌─────────────────────────────────────┐
│         구매 요청서 (제목)           │
├─────────────────────────────────────┤
│ 기본 정보                            │
│  - 요청일: 2026-05-08 14:30:00      │
│  - 상태: 승인됨                      │
│  - 요청자: 김철수 (관리직원)         │
│  - 총 금액: ₩350,000                │
├─────────────────────────────────────┤
│ 구매 사유                            │
│  여름철 냉방 기기 구매 필요...       │
├─────────────────────────────────────┤
│ 물품 목록                            │
│ ┌──────┬────────┬───┬──────┬───────┐│
│ │물품명│카테고리│수량│단가  │금액   ││
│ ├──────┼────────┼───┼──────┼───────┤│
│ │선풍기│가전제품│ 3 │₩50K  │₩150K  ││
│ │에어컨│가전제품│ 2 │₩100K │₩200K  ││
│ └──────┴────────┴───┴──────┴───────┘│
└─────────────────────────────────────┘
```

**📸 2페이지~ - 검수 사진 (이미지-물품 매칭)**
```
┌─────────────────────────────────────┐
│ 검수 사진                            │
├─────────────────────────────────────┤
│                                      │
│  [선풍기 실제 사진 - 큰 이미지]      │
│  (180mm × 100mm)                     │
│                                      │
│  물품명: 선풍기                      │
│  수량: 3 | 단가: ₩50,000 | 총액: ₩150,000│
├─────────────────────────────────────┤
│                                      │
│  [에어컨 실제 사진 - 큰 이미지]      │
│  (180mm × 100mm)                     │
│                                      │
│  물품명: 에어컨                      │
│  수량: 2 | 단가: ₩100,000 | 총액: ₩200,000│
└─────────────────────────────────────┘
```

**✅ 승인/반려 정보 페이지**
- 승인된 경우: 승인자, 승인 시각
- 반려된 경우: 반려 사유

**파일명 형식:**
```
구매요청_[요청자명]_YYYY-MM-DD.pdf
예: 구매요청_김철수_2026-05-08.pdf
```

### 3️⃣ 이미지-물품 자동 매칭 기능

**매칭 방식:**
- 검수 사진(`purchase_photos`)과 물품 목록(`purchase_items`)을 **배열 인덱스로 자동 매칭**
- `purchase_photos[0]` → `purchase_items[0]`
- `purchase_photos[1]` → `purchase_items[1]`
- ...

**PDF 내 표시 형식 (2줄):**
```
[검수 사진 이미지]

물품명: 선풍기
수량: 3 | 단가: ₩50,000 | 총액: ₩150,000
```

**Excel 내 표시 형식:**
| 번호 | 물품명 | 수량 | 단가 | 총액 | 사진 URL |
|------|--------|------|------|------|----------|
| 1 | 선풍기 | 3 | ₩50,000 | ₩150,000 | https://... |
| 2 | 에어컨 | 2 | ₩100,000 | ₩200,000 | https://... |

## 🎨 UI 구현

### 구매 상세 모달 하단 버튼

```
┌────────────────────────────────────────┐
│  [Excel]  [PDF]  [        닫기        ] │
│  (초록색) (빨강)  (       회색        ) │
└────────────────────────────────────────┘
```

**버튼 상세:**
- **Excel 버튼**: 🟢 초록색, `fa-file-excel` 아이콘
- **PDF 버튼**: 🔴 빨간색, `fa-file-pdf` 아이콘
- **닫기 버튼**: ⚪ 회색, 기존 그대로

## 🔧 기술 구현

### Excel 생성
- **라이브러리**: SheetJS (`xlsx.full.min.js`)
- **함수**: `app.exportPurchaseToExcel(purchaseId)`
- **구조**:
  ```javascript
  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.aoa_to_sheet(basicInfo);
  XLSX.utils.book_append_sheet(wb, ws, '구매요청서');
  XLSX.writeFile(wb, fileName);
  ```

### PDF 생성
- **라이브러리**: jsPDF (`jspdf.umd.min.js`)
- **함수**: `app.exportPurchaseToPDF(purchaseId)`
- **이미지 처리**: `app.loadImageAsBase64(url)`
  - Canvas를 사용해 이미지를 Base64로 변환
  - CORS 문제 해결 (`crossOrigin = 'Anonymous'`)
  - PDF에 `doc.addImage()` 메서드로 삽입

### 이미지-물품 매칭
```javascript
for (let i = 0; i < data.purchase_photos.length; i++) {
  const photo = data.purchase_photos[i];
  const item = data.purchase_items[i] || {};
  
  // 이미지 로드 및 PDF 삽입
  const img = await this.loadImageAsBase64(photo.photo_url);
  doc.addImage(img, 'JPEG', margin, yPos, imgWidth, imgHeight);
  
  // 물품 정보 2줄 표시
  doc.text(`물품명: ${item.item_name || '-'}`, margin, yPos);
  doc.text(`수량: ${item.quantity} | 단가: ₩${item.unit_price.toLocaleString()} | 총액: ...`, margin, yPos + 5);
}
```

## 📦 데이터 흐름

```
1. 사용자가 구매 상세 모달 열기
   ↓
2. app.showPurchaseDetail(purchaseId) 호출
   ↓
3. this.currentPurchase에 데이터 저장
   ↓
4. Excel/PDF 버튼 클릭
   ↓
5. app.exportPurchaseToExcel(purchaseId) 
   또는 app.exportPurchaseToPDF(purchaseId) 호출
   ↓
6. this.currentPurchase 데이터 사용
   ↓
7. 파일 생성 및 다운로드
   ↓
8. 성공 알림 표시
```

## ✅ 테스트 시나리오

### Excel 추출 테스트

1. **관리자 페이지 접속**
   ```
   https://bdxi-qr-attendance.vercel.app/index.html?apartment=...
   ```

2. **구매 요청 탭 클릭**

3. **구매 건 선택 → 상세보기**

4. **[Excel] 버튼 클릭**

5. **파일 다운로드 확인**
   - 파일명: `구매요청_[요청자명]_YYYY-MM-DD.xlsx`
   - 파일 열기: Microsoft Excel, Google Sheets, LibreOffice

6. **내용 검증**
   - ✅ 기본 정보 (요청일, 상태, 요청자, 총 금액)
   - ✅ 구매 사유
   - ✅ 물품 목록 (물품명, 카테고리, 수량, 단가, 금액)
   - ✅ 검수 사진 정보 (물품-이미지 매칭)
   - ✅ 승인/반려 정보

### PDF 추출 테스트

1. **관리자 페이지 접속**

2. **구매 요청 탭 클릭**

3. **구매 건 선택 → 상세보기**

4. **[PDF] 버튼 클릭**

5. **파일 다운로드 확인**
   - 파일명: `구매요청_[요청자명]_YYYY-MM-DD.pdf`
   - 파일 열기: Adobe Reader, Chrome, Edge

6. **내용 검증**
   - ✅ 1페이지: 제목, 기본 정보, 구매 사유, 물품 목록
   - ✅ 2페이지~: 검수 사진 (큰 이미지)
   - ✅ 각 사진 하단에 물품 정보 2줄 표시
     - 1줄: 물품명
     - 2줄: 수량 | 단가 | 총액
   - ✅ 승인/반려 정보 (해당되는 경우)

### 이미지-물품 매칭 테스트

1. **검수 사진이 3개, 물품이 3개인 구매 건 선택**

2. **PDF 추출**

3. **확인 사항**
   - ✅ 1번째 사진 → 1번째 물품 정보
   - ✅ 2번째 사진 → 2번째 물품 정보
   - ✅ 3번째 사진 → 3번째 물품 정보

4. **Excel 추출**

5. **확인 사항**
   - ✅ 검수 사진 섹션에 물품명, 수량, 단가, 총액, 사진 URL이 각 행에 표시

## 🔒 에러 처리

### 데이터 없을 때
```javascript
if (!this.currentPurchase || this.currentPurchase.id !== purchaseId) {
  alert('구매 요청 데이터를 먼저 로드해주세요');
  return;
}
```

### 이미지 로드 실패 시
```javascript
try {
  const img = await this.loadImageAsBase64(photo.photo_url);
  doc.addImage(img, 'JPEG', ...);
} catch (imgErr) {
  console.error('이미지 로드 실패:', imgErr);
  doc.text(`[이미지 로드 실패: ${photo.photo_url}]`, ...);
}
```

### 일반 오류
```javascript
try {
  // ... 추출 로직
} catch (err) {
  console.error('❌ PDF 추출 실패:', err);
  alert('PDF 추출 중 오류가 발생했습니다: ' + err.message);
}
```

## 📂 관련 파일

```
/home/user/webapp/
├── index.html                    (메인 파일 - 기능 구현)
│   ├── app.exportPurchaseToExcel()
│   ├── app.exportPurchaseToPDF()
│   └── app.loadImageAsBase64()
└── PURCHASE_EXPORT_FEATURE.md   (이 문서)
```

## 🚀 배포

### Git Commit
```bash
Commit: 4612531
Message: feat(admin): Add Excel/PDF export for purchase requests
Branch: main
```

### Vercel 배포 URL
```
https://bdxi-qr-attendance.vercel.app/index.html
```

## 📊 커밋 통계

```
Files changed: 1
Insertions: +355 lines
Deletions: 0 lines
```

## 🎯 완료된 기능

- ✅ Excel 추출 (기본 정보, 구매 사유, 물품 목록, 검수 사진 정보)
- ✅ PDF 추출 (프로페셔널 레이아웃, 페이지 자동 넘김)
- ✅ 이미지-물품 자동 매칭 (배열 인덱스 기반)
- ✅ 검수 사진 하단에 물품 정보 2줄 표시
- ✅ 이미지를 Base64로 변환하여 PDF 삽입
- ✅ 파일명 자동 생성 (요청자명 + 날짜)
- ✅ UI 버튼 추가 (Excel 초록색, PDF 빨강색)
- ✅ 에러 처리 및 사용자 알림
- ✅ Git 커밋 및 GitHub 푸시
- ✅ Vercel 자동 배포

## 🔜 다음 개선 사항

### 선택 사항 (필요 시 추가 구현)

1. **다중 선택 추출**
   - 여러 구매 건을 선택하여 한 번에 Excel/PDF로 추출

2. **커스텀 템플릿**
   - 관리자가 추출 템플릿을 커스터마이징

3. **이메일 전송**
   - 추출된 파일을 이메일로 바로 전송

4. **인쇄 최적화**
   - PDF 인쇄 시 페이지 레이아웃 최적화

5. **워터마크**
   - 회사 로고 또는 워터마크 추가

6. **한글 폰트 개선**
   - PDF에 Noto Sans KR 폰트 임베딩 (현재는 Helvetica 사용)

## 📞 지원

기능 사용 중 문제가 발생하면:
1. 브라우저 콘솔 확인 (F12)
2. 에러 메시지 스크린샷
3. 구매 요청 ID 확인
4. GitHub Issues에 등록

---

**작성일**: 2026-05-08  
**작성자**: AI Developer  
**버전**: 1.0.0  
**상태**: ✅ 구현 완료 및 배포 완료
