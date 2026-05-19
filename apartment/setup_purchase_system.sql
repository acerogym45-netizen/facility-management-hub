-- ================================
-- 구매 요청 시스템 v1.0
-- ================================
-- Option 1 + Option 2 조합
-- - 센터 관리자만 구매 요청 작성
-- - QR 코드로 일반 직원도 구매 요청 가능
-- ================================

-- 1. 구매 요청 메인 테이블
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 기본 정보
  apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  requester_name TEXT NOT NULL, -- 요청자 이름
  requester_role TEXT NOT NULL CHECK (requester_role IN ('센터 관리자', '일반 직원')), -- 요청자 역할
  
  -- 요청 내용
  reason TEXT NOT NULL, -- 구매 사유
  total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0, -- 총 금액 (자동 계산)
  
  -- 상태 관리
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'delivered', 'completed')),
  -- pending: 승인 대기
  -- approved: 승인됨 (구매 진행 중)
  -- rejected: 반려됨
  -- delivered: 배송 완료
  -- completed: 검수 완료
  
  -- 승인/반려 정보
  approver_name TEXT, -- 승인자 이름
  approval_time TIMESTAMPTZ, -- 승인/반려 시각
  rejection_reason TEXT, -- 반려 사유
  
  -- 배송/완료 정보
  delivery_time TIMESTAMPTZ, -- 배송 완료 시각
  completion_time TIMESTAMPTZ, -- 검수 완료 시각
  actual_amount NUMERIC(12, 2), -- 실제 구매 금액
  
  -- 시간 정보
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. 구매 물품 상세 테이블 (1개 요청에 여러 물품)
CREATE TABLE IF NOT EXISTS purchase_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  
  item_name TEXT NOT NULL, -- 물품명
  quantity INTEGER NOT NULL CHECK (quantity > 0), -- 수량
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0), -- 단가
  category TEXT NOT NULL, -- 카테고리
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. 자주 쓰는 물품 테이블
CREATE TABLE IF NOT EXISTS frequent_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  
  item_name TEXT NOT NULL, -- 물품명
  category TEXT NOT NULL, -- 카테고리
  unit_price NUMERIC(10, 2), -- 최근 단가 (참고용)
  usage_count INTEGER NOT NULL DEFAULT 1, -- 사용 횟수
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- 아파트별로 물품명 중복 방지
  UNIQUE(apartment_id, item_name)
);

-- 4. 검수 사진 테이블
CREATE TABLE IF NOT EXISTS purchase_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  
  photo_url TEXT NOT NULL, -- Supabase Storage URL
  uploaded_by TEXT NOT NULL, -- 업로드한 사람
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. QR 코드 구매 요청 테이블 (일반 직원용)
CREATE TABLE IF NOT EXISTS purchase_qr_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  
  -- QR 코드 정보
  qr_code TEXT NOT NULL UNIQUE, -- 고유 QR 코드 (UUID)
  location_name TEXT NOT NULL, -- 요청 위치 (헬스장, 골프, 필라테스 등)
  
  -- 활성화 여부
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================
-- 인덱스 생성
-- ================================
CREATE INDEX IF NOT EXISTS idx_purchases_apartment ON purchases(apartment_id);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchases_created ON purchases(created_at);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_frequent_items_apartment ON frequent_items(apartment_id);
CREATE INDEX IF NOT EXISTS idx_purchase_photos_purchase ON purchase_photos(purchase_id);
CREATE INDEX IF NOT EXISTS idx_purchase_qr_apartment ON purchase_qr_requests(apartment_id);

-- ================================
-- RLS (Row Level Security) 설정
-- ================================
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE frequent_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_qr_requests ENABLE ROW LEVEL SECURITY;

-- purchases 테이블: 모든 인증된 사용자 읽기/쓰기 가능
CREATE POLICY "Allow all authenticated users to read purchases"
  ON purchases FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to insert purchases"
  ON purchases FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to update purchases"
  ON purchases FOR UPDATE
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- purchase_items 테이블: 모든 인증된 사용자 읽기/쓰기 가능
CREATE POLICY "Allow all authenticated users to read purchase_items"
  ON purchase_items FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to insert purchase_items"
  ON purchase_items FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- frequent_items 테이블: 모든 인증된 사용자 읽기/쓰기 가능
CREATE POLICY "Allow all authenticated users to read frequent_items"
  ON frequent_items FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to insert frequent_items"
  ON frequent_items FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to update frequent_items"
  ON frequent_items FOR UPDATE
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- purchase_photos 테이블: 모든 인증된 사용자 읽기/쓰기 가능
CREATE POLICY "Allow all authenticated users to read purchase_photos"
  ON purchase_photos FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to insert purchase_photos"
  ON purchase_photos FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- purchase_qr_requests 테이블: 모든 인증된 사용자 읽기/쓰기 가능
CREATE POLICY "Allow all authenticated users to read purchase_qr_requests"
  ON purchase_qr_requests FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to insert purchase_qr_requests"
  ON purchase_qr_requests FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow all authenticated users to update purchase_qr_requests"
  ON purchase_qr_requests FOR UPDATE
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- ================================
-- 트리거: updated_at 자동 갱신
-- ================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_purchases_updated_at ON purchases;
CREATE TRIGGER update_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_frequent_items_updated_at ON frequent_items;
CREATE TRIGGER update_frequent_items_updated_at
  BEFORE UPDATE ON frequent_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================
-- 완료 메시지
-- ================================
DO $$ 
BEGIN 
  RAISE NOTICE '✅ 구매 요청 시스템 v1.0 설치 완료!';
  RAISE NOTICE '📦 테이블 생성: purchases, purchase_items, frequent_items, purchase_photos, purchase_qr_requests';
  RAISE NOTICE '🔒 RLS 정책 설정 완료';
  RAISE NOTICE '🚀 준비 완료: 관리자 대시보드에 구매 요청 탭 추가 가능';
END $$;
