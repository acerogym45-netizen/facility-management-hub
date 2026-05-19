# 검수 사진-물품 매칭 시스템 설계

## 현재 상황
- 검수 사진: 그냥 업로드만 되고 어떤 물품인지 알 수 없음
- 물품 목록: 사진과 연결되지 않음
- 문제: 관리자가 어떤 사진이 어떤 물품인지 수동으로 확인해야 함

## 해결 방안

### 옵션 1: DB 스키마 수정 (권장)
```sql
-- purchase_photos 테이블에 컬럼 추가
ALTER TABLE purchase_photos 
ADD COLUMN purchase_item_id UUID REFERENCES purchase_items(id);
```

**장점:**
- 정확한 1:1 매칭
- 한 물품에 여러 사진 가능
- 나중에 물품별 검색/필터링 가능

**단점:**
- DB 스키마 수정 필요
- 업로드 시 물품 선택 UI 추가 필요

### 옵션 2: 순서 기반 자동 매칭 (간단)
```javascript
// 업로드 순서 = 물품 목록 순서
photos[0] → items[0]
photos[1] → items[1]
...
```

**장점:**
- DB 수정 불필요
- 간단한 구현
- 빠른 배포

**단점:**
- 부정확할 수 있음
- 사진이 물품보다 많거나 적으면 문제
- 순서 변경 시 매칭 깨짐

### 옵션 3: 파일명 기반 매칭 (중간)
```javascript
// 파일명에 물품 정보 포함
"김밥_1.jpg" → 김밥
"콜라_2.jpg" → 콜라
```

**장점:**
- DB 수정 불필요
- 명시적
- 순서 무관

**단점:**
- 사용자가 파일명 규칙 지켜야 함
- 한글 파일명 문제 (이미 해결했지만)
- 자동화 어려움

## 추천: 옵션 1 (DB 스키마 수정)

### 단계별 구현

#### 1단계: DB 스키마 업데이트
```sql
-- Supabase에서 실행
ALTER TABLE purchase_photos 
ADD COLUMN purchase_item_id UUID REFERENCES purchase_items(id);

CREATE INDEX idx_purchase_photos_item_id 
ON purchase_photos(purchase_item_id);
```

#### 2단계: 업로드 UI 개선
```html
<!-- 물품 선택 드롭다운 추가 -->
<select id="photo-item-selector">
  <option value="">선택하세요</option>
  <option value="item-1-id">김밥 (1개)</option>
  <option value="item-2-id">콜라 (2개)</option>
</select>
```

#### 3단계: 업로드 로직 수정
```javascript
const photoData = {
  purchase_id: currentPurchaseIdForPhoto,
  purchase_item_id: selectedItemId, // 새로 추가
  photo_url: urlData.publicUrl,
  uploaded_by: app.currentAdmin?.id || systemUserId
};
```

#### 4단계: 상세 페이지 표시 개선
```html
<!-- 물품별로 그룹화해서 표시 -->
<div class="item-section">
  <h4>김밥 (1개)</h4>
  <div class="photos">
    <img src="photo1.jpg">
    <img src="photo2.jpg">
  </div>
</div>
```

## 임시 해결책 (당장 구현 가능)

DB 스키마 수정 없이 **순서 기반 매칭 + 메모 필드** 사용:

```javascript
// 사진 업로드 시 메모 입력
const photoData = {
  purchase_id: currentPurchaseIdForPhoto,
  photo_url: urlData.publicUrl,
  uploaded_by: app.currentAdmin?.id || systemUserId,
  note: "김밥 검수 사진" // ← 메모 필드 활용
};
```

**장점:**
- 즉시 구현 가능
- DB 수정 불필요
- 유연성

**단점:**
- 수동 입력 필요
- 자동 매칭 불가

## 결론

**단기 (지금):**
- 사진 업로드 시 메모 필드에 물품명 입력
- 상세 페이지에서 메모 표시

**중기 (1주일 내):**
- DB 스키마에 `purchase_item_id` 컬럼 추가
- 업로드 UI에 물품 선택 드롭다운 추가
- 물품별 그룹화 표시

**장기 (1개월 내):**
- AI 이미지 인식으로 자동 매칭
- 사진에서 물품명 자동 추출
- 중복 사진 감지
