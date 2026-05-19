-- vacations 테이블 빠른 수정 (기존 데이터 유지)

-- 1. 기존 테이블에 end_date 컬럼이 없다면 추가
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS end_date DATE;

-- 2. 다른 필요한 컬럼들도 추가
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS vacation_type TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS reason TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS admin_comment TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS approved_by TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS employee_id UUID;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS apartment_id UUID;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. 제약 조건 추가 (이미 있다면 무시됨)
DO $$ 
BEGIN
    -- start_date NOT NULL 제약
    BEGIN
        ALTER TABLE vacations ALTER COLUMN start_date SET NOT NULL;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'start_date constraint already exists or cannot be added';
    END;
    
    -- end_date NOT NULL 제약
    BEGIN
        ALTER TABLE vacations ALTER COLUMN end_date SET NOT NULL;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'end_date constraint already exists or cannot be added';
    END;
    
    -- 날짜 범위 체크 제약
    BEGIN
        ALTER TABLE vacations ADD CONSTRAINT valid_date_range CHECK (end_date >= start_date);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'valid_date_range constraint already exists';
    END;
    
    -- vacation_type 체크 제약
    BEGIN
        ALTER TABLE vacations ADD CONSTRAINT valid_vacation_type 
            CHECK (vacation_type IN ('annual', 'half_day', 'sick', 'personal', 'other'));
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'valid_vacation_type constraint already exists';
    END;
    
    -- status 체크 제약
    BEGIN
        ALTER TABLE vacations ADD CONSTRAINT valid_status 
            CHECK (status IN ('pending', 'approved', 'rejected'));
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'valid_status constraint already exists';
    END;
END $$;

-- 4. 인덱스 추가 (이미 있다면 무시됨)
CREATE INDEX IF NOT EXISTS idx_vacations_employee ON vacations(employee_id);
CREATE INDEX IF NOT EXISTS idx_vacations_apartment ON vacations(apartment_id);
CREATE INDEX IF NOT EXISTS idx_vacations_status ON vacations(status);
CREATE INDEX IF NOT EXISTS idx_vacations_dates ON vacations(start_date, end_date);

-- 완료 메시지
SELECT '✅ vacations 테이블이 업데이트되었습니다!' AS message;
