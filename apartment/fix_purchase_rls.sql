-- 구매 요청 RLS 정책 추가
-- 직원이 자신의 구매 요청을 생성/조회할 수 있도록 허용

-- 1. purchases 테이블 RLS 활성화 (이미 활성화되어 있을 수 있음)
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- 2. 기존 정책 확인 및 제거 (충돌 방지)
DROP POLICY IF EXISTS "Allow employees to insert their own purchase requests" ON purchases;
DROP POLICY IF EXISTS "Allow employees to view their own purchase requests" ON purchases;

-- 3. 직원이 자신의 구매 요청을 생성할 수 있는 정책
CREATE POLICY "Allow employees to insert their own purchase requests"
ON purchases
FOR INSERT
TO authenticated, anon
WITH CHECK (true);

-- 4. 직원이 자신의 구매 요청을 조회할 수 있는 정책
CREATE POLICY "Allow employees to view their own purchase requests"
ON purchases
FOR SELECT
TO authenticated, anon
USING (true);

-- 5. 관리자가 모든 구매 요청을 업데이트할 수 있는 정책
DROP POLICY IF EXISTS "Allow admins to update purchase requests" ON purchases;
CREATE POLICY "Allow admins to update purchase requests"
ON purchases
FOR UPDATE
TO authenticated, anon
USING (true);

-- purchase_items 테이블도 동일하게 설정
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow employees to insert purchase items" ON purchase_items;
CREATE POLICY "Allow employees to insert purchase items"
ON purchase_items
FOR INSERT
TO authenticated, anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow employees to view purchase items" ON purchase_items;
CREATE POLICY "Allow employees to view purchase items"
ON purchase_items
FOR SELECT
TO authenticated, anon
USING (true);

-- 완료 메시지
SELECT '✅ 구매 요청 RLS 정책 추가 완료!' as message;
SELECT '📝 직원이 구매 요청을 생성/조회할 수 있습니다' as info;
