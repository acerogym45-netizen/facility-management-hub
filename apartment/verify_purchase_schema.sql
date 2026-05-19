-- ========================================
-- 구매 요청 시스템 스키마 검증 스크립트
-- ========================================

-- 1️⃣ purchases 테이블 컬럼 확인
SELECT 
  '1️⃣ purchases 테이블 컬럼' AS step,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'purchases'
ORDER BY ordinal_position;

-- 2️⃣ purchase_items 테이블 컬럼 확인
SELECT 
  '2️⃣ purchase_items 테이블 컬럼' AS step,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'purchase_items'
ORDER BY ordinal_position;

-- 3️⃣ RLS 정책 확인
SELECT 
  '3️⃣ RLS 정책' AS step,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('purchases', 'purchase_items')
ORDER BY tablename, policyname;

-- 4️⃣ 테이블 권한 확인
SELECT 
  '4️⃣ 테이블 권한' AS step,
  grantee,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.table_privileges
WHERE table_name IN ('purchases', 'purchase_items')
  AND grantee IN ('anon', 'authenticated', 'service_role')
ORDER BY table_name, grantee, privilege_type;

-- 5️⃣ Foreign Key 확인
SELECT 
  '5️⃣ Foreign Key' AS step,
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('purchases', 'purchase_items')
ORDER BY tc.table_name, tc.constraint_name;

-- 6️⃣ 인덱스 확인
SELECT 
  '6️⃣ 인덱스' AS step,
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename IN ('purchases', 'purchase_items')
ORDER BY tablename, indexname;

-- 7️⃣ 최근 purchases 레코드 샘플 (최대 3개)
SELECT 
  '7️⃣ 최근 구매 요청' AS step,
  id,
  apartment_id,
  requester_name,
  requester_employee_id,
  status,
  total_amount,
  created_at
FROM purchases
ORDER BY created_at DESC
LIMIT 3;

SELECT '✅ 스키마 검증 완료!' AS message;
