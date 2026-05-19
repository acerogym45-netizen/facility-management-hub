-- ============================================================
-- 인기 서류 VIEW 생성 (Optional)
-- Create Popular Documents View (Optional)
-- ============================================================
--
-- 목적: document_templates_popular VIEW 생성
-- 필요한 경우: 인기 서류 목록 기능 사용 시
-- 우선순위: 낮음 (핵심 기능 아님)
--
-- ============================================================

CREATE OR REPLACE VIEW document_templates_popular AS
SELECT 
  d.*,
  COUNT(df.id) as favorite_count,
  dc.name as category_name,
  dc.icon as category_icon,
  dc.color as category_color
FROM documents d
LEFT JOIN document_favorites df ON d.id = df.document_id
LEFT JOIN document_categories dc ON d.category_id = dc.id
WHERE d.is_active = true
GROUP BY d.id, dc.name, dc.icon, dc.color
ORDER BY favorite_count DESC, d.created_at DESC
LIMIT 10;

-- 권한 부여
GRANT SELECT ON document_templates_popular TO anon, authenticated;

-- ============================================================
-- 테스트 쿼리
-- ============================================================

SELECT * FROM document_templates_popular;

-- 예상 결과:
-- - 즐겨찾기가 많은 서류 10개
-- - 카테고리 정보 포함
-- - favorite_count 컬럼 (즐겨찾기 수)
