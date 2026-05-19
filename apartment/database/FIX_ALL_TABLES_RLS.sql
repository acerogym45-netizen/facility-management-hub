-- ============================================================
-- 전체 테이블 RLS 정책 수정 (ALL TABLES FIX)
-- Fix RLS Policies for All Tables - Allow Anonymous Access
-- ============================================================
--
-- 문제: 이전 SQL에서 documents 관련만 수정하여 다른 테이블 접근 불가
-- 해결: 모든 주요 테이블에 anon 역할 허용
--
-- ============================================================

-- 1. apartments (단지 관리)
DROP POLICY IF EXISTS "Enable read access for all users" ON apartments;
DROP POLICY IF EXISTS "Enable insert for all users" ON apartments;
DROP POLICY IF EXISTS "Enable update for all users" ON apartments;
DROP POLICY IF EXISTS "Enable delete for all users" ON apartments;

CREATE POLICY "Enable read access for all users" ON apartments FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON apartments FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON apartments FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for all users" ON apartments FOR DELETE USING (true);

-- 2. employees (직원 관리)
DROP POLICY IF EXISTS "Enable read access for all users" ON employees;
DROP POLICY IF EXISTS "Enable insert for all users" ON employees;
DROP POLICY IF EXISTS "Enable update for all users" ON employees;
DROP POLICY IF EXISTS "Enable delete for all users" ON employees;

CREATE POLICY "Enable read access for all users" ON employees FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON employees FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON employees FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for all users" ON employees FOR DELETE USING (true);

-- 3. attendance_records (출퇴근 기록)
DROP POLICY IF EXISTS "Enable read access for all users" ON attendance_records;
DROP POLICY IF EXISTS "Enable insert for all users" ON attendance_records;
DROP POLICY IF EXISTS "Enable update for all users" ON attendance_records;
DROP POLICY IF EXISTS "Enable delete for all users" ON attendance_records;

CREATE POLICY "Enable read access for all users" ON attendance_records FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON attendance_records FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON attendance_records FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for all users" ON attendance_records FOR DELETE USING (true);

-- 4. attendance_notes (출퇴근 메모)
DROP POLICY IF EXISTS "Enable all for all users" ON attendance_notes;
CREATE POLICY "Enable all for all users" ON attendance_notes FOR ALL USING (true) WITH CHECK (true);

-- 5. attendance_edit_logs (출퇴근 수정 로그)
DROP POLICY IF EXISTS "Enable all for all users" ON attendance_edit_logs;
CREATE POLICY "Enable all for all users" ON attendance_edit_logs FOR ALL USING (true) WITH CHECK (true);

-- 6. vacations (휴가)
DROP POLICY IF EXISTS "Enable all for all users" ON vacations;
CREATE POLICY "Enable all for all users" ON vacations FOR ALL USING (true) WITH CHECK (true);

-- 7. holidays (공휴일)
DROP POLICY IF EXISTS "Enable all for all users" ON holidays;
CREATE POLICY "Enable all for all users" ON holidays FOR ALL USING (true) WITH CHECK (true);

-- 8. purchases (구매 요청)
DROP POLICY IF EXISTS "Enable all for all users" ON purchases;
CREATE POLICY "Enable all for all users" ON purchases FOR ALL USING (true) WITH CHECK (true);

-- 9. purchase_items (구매 항목)
DROP POLICY IF EXISTS "Enable all for all users" ON purchase_items;
CREATE POLICY "Enable all for all users" ON purchase_items FOR ALL USING (true) WITH CHECK (true);

-- 10. purchase_photos (구매 사진)
DROP POLICY IF EXISTS "Enable all for all users" ON purchase_photos;
CREATE POLICY "Enable all for all users" ON purchase_photos FOR ALL USING (true) WITH CHECK (true);

-- 11. purchase_qr_requests (QR 요청)
DROP POLICY IF EXISTS "Enable all for all users" ON purchase_qr_requests;
CREATE POLICY "Enable all for all users" ON purchase_qr_requests FOR ALL USING (true) WITH CHECK (true);

-- 12. frequent_items (자주 쓰는 항목)
DROP POLICY IF EXISTS "Enable all for all users" ON frequent_items;
CREATE POLICY "Enable all for all users" ON frequent_items FOR ALL USING (true) WITH CHECK (true);

-- 13. locations (위치)
DROP POLICY IF EXISTS "Enable all for all users" ON locations;
CREATE POLICY "Enable all for all users" ON locations FOR ALL USING (true) WITH CHECK (true);

-- 14. sales (판매)
DROP POLICY IF EXISTS "Enable all for all users" ON sales;
CREATE POLICY "Enable all for all users" ON sales FOR ALL USING (true) WITH CHECK (true);

-- 15. cleaning_tasks (청소 작업)
DROP POLICY IF EXISTS "Enable all for all users" ON cleaning_tasks;
CREATE POLICY "Enable all for all users" ON cleaning_tasks FOR ALL USING (true) WITH CHECK (true);

-- 16. document_downloads (문서 다운로드)
DROP POLICY IF EXISTS "Enable all for all users" ON document_downloads;
CREATE POLICY "Enable all for all users" ON document_downloads FOR ALL USING (true) WITH CHECK (true);

-- 17. document_views (문서 조회)
DROP POLICY IF EXISTS "Enable all for all users" ON document_views;
CREATE POLICY "Enable all for all users" ON document_views FOR ALL USING (true) WITH CHECK (true);

-- 18. document_notifications (문서 알림)
DROP POLICY IF EXISTS "Enable all for all users" ON document_notifications;
CREATE POLICY "Enable all for all users" ON document_notifications FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- Storage 정책 - 모든 버킷 허용
-- ============================================================

-- purchases 버킷
DROP POLICY IF EXISTS "Allow upload to purchases" ON storage.objects;
DROP POLICY IF EXISTS "Allow read from purchases" ON storage.objects;
DROP POLICY IF EXISTS "Allow update in purchases" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete from purchases" ON storage.objects;

CREATE POLICY "Allow upload to purchases" ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'purchases');

CREATE POLICY "Allow read from purchases" ON storage.objects FOR SELECT 
USING (bucket_id = 'purchases');

CREATE POLICY "Allow update in purchases" ON storage.objects FOR UPDATE 
USING (bucket_id = 'purchases') WITH CHECK (bucket_id = 'purchases');

CREATE POLICY "Allow delete from purchases" ON storage.objects FOR DELETE 
USING (bucket_id = 'purchases');

-- ============================================================
-- 확인 쿼리
-- ============================================================

SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename IN (
  'apartments', 'employees', 'attendance_records', 'attendance_notes',
  'attendance_edit_logs', 'vacations', 'holidays', 'purchases', 
  'purchase_items', 'purchase_photos', 'purchase_qr_requests',
  'frequent_items', 'locations', 'sales', 'cleaning_tasks',
  'document_downloads', 'document_views', 'document_notifications',
  'documents', 'document_categories', 'document_favorites', 
  'document_versions', 'document_tags'
)
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Storage 정책 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- ============================================================
-- 예상 결과:
-- ============================================================
-- 
-- ✅ 모든 테이블에 1~4개 정책 존재
-- ✅ Storage에 document-templates, purchases 정책 존재
-- ✅ 모든 정책의 roles = {public}
-- 
-- 이제 모든 기능 정상 작동
--
-- ============================================================
