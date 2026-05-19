-- vacations 테이블 빠른 수정 (vacation_date 오류 해결)

-- vacation_date 컬럼 삭제 (잘못 생성된 컬럼)
ALTER TABLE vacations DROP COLUMN IF EXISTS vacation_date CASCADE;

-- 필수 컬럼 확인
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS vacation_type TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS reason TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS employee_id UUID;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS apartment_id UUID;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS admin_comment TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS approved_by TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- RLS 비활성화 (이미 했다면 무시됨)
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;

-- 완료 메시지
SELECT '✅ vacations 테이블이 수정되었습니다!' AS message;
