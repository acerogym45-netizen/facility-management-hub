-- ==========================================
-- Supabase Database Schema for BDXI QR Attendance System
-- ==========================================

-- 1. monthly_settlements (정산서 관리)
CREATE TABLE IF NOT EXISTS public.monthly_settlements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  year_month VARCHAR(7) NOT NULL, -- 'YYYY-MM' 형식
  
  -- 통계 정보
  total_employees INTEGER DEFAULT 0,
  total_work_days INTEGER DEFAULT 0,
  total_work_hours DECIMAL(10,2) DEFAULT 0,
  total_overtime_hours DECIMAL(10,2) DEFAULT 0,
  total_late_count INTEGER DEFAULT 0,
  total_absent_count INTEGER DEFAULT 0,
  
  -- 상태 관리
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected')),
  
  -- Excel 파일
  excel_file_url TEXT,
  excel_file_name TEXT,
  
  -- 제출 및 검토
  submitted_by UUID REFERENCES public.employees(id),
  submitted_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  review_comment TEXT,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 중복 방지 제약
  UNIQUE(apartment_id, year_month)
);

-- 2. payroll_statements (급여명세서)
CREATE TABLE IF NOT EXISTS public.payroll_statements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  year_month VARCHAR(7) NOT NULL, -- 'YYYY-MM' 형식
  
  -- 급여 정보
  base_salary DECIMAL(12,2) DEFAULT 0,
  overtime_pay DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  deductions DECIMAL(12,2) DEFAULT 0,
  total_salary DECIMAL(12,2) DEFAULT 0,
  
  -- 근무 정보
  work_days INTEGER DEFAULT 0,
  work_hours DECIMAL(10,2) DEFAULT 0,
  overtime_hours DECIMAL(10,2) DEFAULT 0,
  
  -- PDF 파일
  pdf_file_url TEXT,
  pdf_file_name TEXT,
  
  -- 상태
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'downloaded')),
  viewed_at TIMESTAMP WITH TIME ZONE,
  downloaded_at TIMESTAMP WITH TIME ZONE,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 중복 방지 제약
  UNIQUE(employee_id, year_month)
);

-- 3. 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_apartment_id ON public.monthly_settlements(apartment_id);
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_year_month ON public.monthly_settlements(year_month);
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_status ON public.monthly_settlements(status);

CREATE INDEX IF NOT EXISTS idx_payroll_statements_apartment_id ON public.payroll_statements(apartment_id);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_employee_id ON public.payroll_statements(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_year_month ON public.payroll_statements(year_month);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_status ON public.payroll_statements(status);

-- 4. RLS (Row Level Security) 활성화
ALTER TABLE public.monthly_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_statements ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성 (모든 사용자가 읽기/쓰기 가능 - 개발 환경)
CREATE POLICY "Enable all access for authenticated users" ON public.monthly_settlements
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.payroll_statements
  FOR ALL USING (true) WITH CHECK (true);

-- 6. updated_at 자동 업데이트 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_monthly_settlements_updated_at
  BEFORE UPDATE ON public.monthly_settlements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payroll_statements_updated_at
  BEFORE UPDATE ON public.payroll_statements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 완료!
-- ==========================================
-- 이 SQL 파일을 Supabase SQL Editor에서 실행하세요.
-- Dashboard > SQL Editor > New Query
