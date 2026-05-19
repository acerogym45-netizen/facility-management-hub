-- ========================================
-- Cleaning Tasks Schema Update
-- Add Before/After and Multi-Photo Support
-- ========================================

-- 1. Add before_after column (before, after, or null)
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS before_after TEXT;

COMMENT ON COLUMN cleaning_tasks.before_after IS 'Values: before, after, or null for regular photos';

-- 2. Add photo_urls column for multiple photos (JSONB array)
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS photo_urls JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN cleaning_tasks.photo_urls IS 'Array of photo URLs for multi-photo uploads';

-- 3. Add photo_count column
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS photo_count INTEGER DEFAULT 1;

COMMENT ON COLUMN cleaning_tasks.photo_count IS 'Number of photos in this record';

-- 4. Add photo_order column (for before/after ordering)
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS photo_order INTEGER DEFAULT 0;

COMMENT ON COLUMN cleaning_tasks.photo_order IS 'Order of photo in a group (0=before, 1=after)';

-- 5. Add upload_type column
ALTER TABLE cleaning_tasks 
ADD COLUMN IF NOT EXISTS upload_type TEXT DEFAULT 'single';

COMMENT ON COLUMN cleaning_tasks.upload_type IS 'Type: single, multi, before_after';

-- 6. Create indexes for faster filtering
CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_before_after 
ON cleaning_tasks(before_after);

CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_group_id 
ON cleaning_tasks(group_id);

CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_upload_type 
ON cleaning_tasks(upload_type);

-- 7. Verify all columns were added
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'cleaning_tasks' 
AND column_name IN ('before_after', 'photo_count', 'photo_urls', 'group_id', 'photo_order', 'upload_type')
ORDER BY column_name;
