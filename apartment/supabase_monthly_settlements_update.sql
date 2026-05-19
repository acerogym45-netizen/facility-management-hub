-- ==========================================
-- Add missing columns to monthly_settlements table
-- For B-4: Settlement Management Feature
-- ==========================================

-- Add apartment_name for display purposes
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS apartment_name VARCHAR(255);

-- Add date range columns
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;

-- Add salary totals
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS total_base_salary DECIMAL(15,2) DEFAULT 0;

-- Add employee details (JSONB to store per-employee salary breakdown)
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS employee_details JSONB;

-- Add creator name (for audit trail)
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS created_by_name VARCHAR(100);

-- Add submitted_by_name for when user info not in employees table
ALTER TABLE public.monthly_settlements 
ADD COLUMN IF NOT EXISTS submitted_by_name VARCHAR(100);

-- Add comments for documentation
COMMENT ON COLUMN public.monthly_settlements.apartment_name IS '아파트명 (캐시용)';
COMMENT ON COLUMN public.monthly_settlements.start_date IS '정산 시작일';
COMMENT ON COLUMN public.monthly_settlements.end_date IS '정산 종료일';
COMMENT ON COLUMN public.monthly_settlements.total_base_salary IS '총 기본급 (기본급 + 직책수당)';
COMMENT ON COLUMN public.monthly_settlements.employee_details IS '직원별 급여 상세 (JSONB: employee_id, name, position, base_salary, allowances, deductions, total)';
COMMENT ON COLUMN public.monthly_settlements.created_by_name IS '생성자 이름';
COMMENT ON COLUMN public.monthly_settlements.submitted_by_name IS '제출자 이름';

-- Create index on employee_details for faster queries
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_employee_details 
ON public.monthly_settlements USING gin(employee_details);

-- Update existing records to set apartment_name from apartments table
UPDATE public.monthly_settlements ms
SET apartment_name = a.name
FROM public.apartments a
WHERE ms.apartment_id = a.id AND ms.apartment_name IS NULL;

-- Success message
DO $$ 
BEGIN
  RAISE NOTICE 'Successfully added columns to monthly_settlements table';
  RAISE NOTICE 'Added: apartment_name, start_date, end_date, total_base_salary, employee_details, created_by_name, submitted_by_name';
END $$;
