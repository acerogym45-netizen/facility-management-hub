# 구매 요청 시스템 설치 가이드

## 📦 시스템 개요

**Option 1 + Option 2 조합**으로 구현된 구매 요청 시스템:
- ✅ **센터 관리자**: 대시보드에서 직접 구매 요청 작성
- ✅ **일반 직원**: QR 코드 스캔하여 구매 요청 가능

## 🗄️ 데이터베이스 설치

### 1. Supabase SQL Editor 열기
https://supabase.com/dashboard/project/qgpqhtuynxhmgawakjxe → SQL Editor → New Query

### 2. SQL 스크립트 실행
`setup_purchase_system.sql` 파일의 전체 내용을 복사하여 실행

### 생성되는 테이블:
- `purchases` - 구매 요청 메인 테이블
- `purchase_items` - 구매 물품 상세
- `frequent_items` - 자주 쓰는 물품 (자동완성용)
- `purchase_photos` - 검수 사진
- `purchase_qr_requests` - QR 코드 관리

## 🎯 주요 기능

### 📊 대시보드
- 승인 대기 건수
- 반려 건수
- 이번 달 구매 현황 (금액 & 건수)

### 🛒 구매 요청 작성
- 여러 물품 동시 등록
- 자주 쓰는 물품 자동완성
- 실시간 총 금액 계산

### ✅ 승인 워크플로우
```
요청 → 승인/반려 → 배송 완료 → 검수 사진 업로드 → 완료
```

### 🔍 필터링
- 상태별 필터 (전체/승인대기/승인됨/반려/배송완료/검수완료)
- 날짜 범위 필터
- 물품명/요청자 검색

## 📱 QR 코드 시스템

### QR 코드 생성
1. 관리자 대시보드 → **구매 요청** 탭
2. **QR 코드 관리** 버튼 클릭
3. 위치 입력 (예: 헬스장, 골프장)
4. **생성** 버튼 클릭
5. **다운로드** 아이콘으로 QR 이미지 저장

### 일반 직원 사용 방법
1. QR 코드 스캔
2. 구매 요청 페이지 자동 열림
3. 요청자 이름, 구매 사유, 물품 입력
4. **요청 등록** 버튼 클릭
5. 센터 관리자 승인 대기

## 🎨 UI 구성

### 관리자 대시보드 (index.html)
- 새 탭: **구매 요청** (데이터 관리와 업무 일지 사이)
- 3개 통계 카드 (승인대기/반려/이번달구매)
- 필터링 기능
- 구매 요청 목록 테이블

### 모달 창
1. **새 구매 요청 모달** - 구매 요청 작성
2. **구매 요청 상세 모달** - 상세 보기 & 액션
3. **QR 코드 관리 모달** - QR 생성/관리
4. **검수 사진 업로드 모달** - 사진 업로드 & 실제 금액 입력

### 직원용 페이지 (purchase-request.html)
- 모바일 최적화
- 간단한 입력 폼
- 자주 쓰는 물품 자동완성

## 🔄 상태 흐름

| 상태 | 설명 | 가능한 액션 |
|------|------|------------|
| `pending` | 승인 대기 | 승인 / 반려 |
| `approved` | 승인됨 | 배송 완료 |
| `rejected` | 반려됨 | (없음) |
| `delivered` | 배송 완료 | 검수 완료 |
| `completed` | 검수 완료 | (없음) |

## 📸 검수 사진 업로드

### Supabase Storage 설정 필요
1. Supabase Dashboard → Storage
2. 새 Bucket 생성: `purchase-photos`
3. Public access 활성화
4. RLS 정책 설정:
```sql
-- 모든 인증된 사용자가 업로드 가능
CREATE POLICY "Allow authenticated uploads"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'purchase-photos' AND
    (auth.role() = 'authenticated' OR auth.role() = 'anon')
  );

-- 모든 사용자가 읽기 가능
CREATE POLICY "Allow public access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'purchase-photos');
```

## 🚀 배포 정보

### GitHub Repository
https://github.com/acerogym45-netizen/BDXI-QR-attendance

### Vercel 자동 배포
- URL: https://bdxi-qr-attendance.vercel.app
- 관리자 대시보드: `/index.html`
- 직원 구매 요청: `/purchase-request.html?qr={QR_CODE}`

## 📝 사용 시나리오

### 시나리오 1: 센터 관리자가 직접 요청
1. 대시보드 로그인
2. **구매 요청** 탭 클릭
3. **새 구매 요청** 버튼
4. 물품 정보 입력
5. **요청 등록**
6. 자동으로 승인 대기 상태

### 시나리오 2: 일반 직원이 QR로 요청
1. 헬스장/골프장 등에 비치된 QR 스캔
2. 구매 요청 페이지 열림
3. 이름, 사유, 물품 입력
4. **요청 등록**
5. 센터 관리자에게 승인 요청

### 시나리오 3: 관리자 승인 및 검수
1. **구매 요청** 탭에서 대기 중인 요청 확인
2. 상세보기 → **승인** 버튼
3. 구매 진행
4. 배송 완료 시 **배송 완료** 버튼
5. 검수 후 **검수 완료** 버튼
6. 사진 업로드 & 실제 금액 입력
7. 완료

## 🎉 완료 확인

### 1. 데이터베이스 확인
```sql
-- 테이블 존재 확인
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('purchases', 'purchase_items', 'frequent_items', 'purchase_photos', 'purchase_qr_requests');
```

### 2. 대시보드 확인
- 로그인 후 **구매 요청** 탭 표시 확인
- 통계 카드 3개 표시 확인

### 3. QR 시스템 확인
- QR 코드 생성 가능 확인
- QR 다운로드 가능 확인

## 🐛 문제 해결

### "purchase-photos 버킷이 없습니다" 에러
→ Supabase Storage에서 `purchase-photos` 버킷 생성 필요

### QR 스캔 시 "유효하지 않은 QR 코드" 에러
→ QR 관리 모달에서 해당 QR가 **활성** 상태인지 확인

### 사진 업로드 실패
→ Supabase Storage RLS 정책 확인 필요

## 📞 다음 작업

1. ✅ 구매 요청 시스템 (완료)
2. ⏳ 세금계산서 자동 분배 시스템
3. ⏳ 센터별 규정/SOP 아카이브
4. ⏳ PT/골프/필라테스 계약서 아카이브

---

## 📌 추가 문의
구매 요청 시스템이 정상적으로 작동하는지 테스트 후 다음 작업을 진행하겠습니다.
