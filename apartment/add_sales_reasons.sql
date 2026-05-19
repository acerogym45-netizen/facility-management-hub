-- sales 테이블에 증감 요인 컬럼 추가
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS increase_reason TEXT,
ADD COLUMN IF NOT EXISTS decrease_reason TEXT;

-- 기존 데이터 업데이트 (선택사항)
UPDATE sales 
SET increase_reason = NULL, decrease_reason = NULL 
WHERE increase_reason IS NULL OR decrease_reason IS NULL;

COMMENT ON COLUMN sales.increase_reason IS '매출 상승 요인';
COMMENT ON COLUMN sales.decrease_reason IS '매출 하락 요인';
