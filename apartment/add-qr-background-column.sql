-- Add qr_background column to locations table
ALTER TABLE locations 
ADD COLUMN IF NOT EXISTS qr_background VARCHAR(50) DEFAULT 'fitness';

-- Update comment
COMMENT ON COLUMN locations.qr_background IS 'QR 코드 배경 이미지 타입 (fitness, golf, information, pool, sauna)';

-- 기존 데이터에 기본값 설정
UPDATE locations 
SET qr_background = 'fitness' 
WHERE qr_background IS NULL;
