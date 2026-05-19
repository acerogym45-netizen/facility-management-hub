-- ==========================================
-- Supabase Database Schema for BDXI QR Attendance System
-- Complete Schema - All Tables
-- ==========================================

-- ==========================================
-- Phase B: Settlements & Payroll
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

-- ==========================================
-- Phase C: Complaints & Sales
-- ==========================================

-- 3. complaints (민원 관리)
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  
  -- 민원 정보
  title VARCHAR(200) NOT NULL,
  description TEXT,
  category VARCHAR(50) DEFAULT 'general' CHECK (category IN ('general', 'facility', 'cleaning', 'security', 'parking', 'noise', 'other')),
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- 상태 관리
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected', 'closed')),
  
  -- 제보자 정보
  reporter_name VARCHAR(100),
  reporter_phone VARCHAR(20),
  reporter_unit VARCHAR(50),
  
  -- 처리 정보
  assigned_to UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  resolved_by UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolution_note TEXT,
  
  -- 첨부 파일
  attachment_url TEXT,
  attachment_name TEXT,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. sales (매출 관리)
CREATE TABLE IF NOT EXISTS public.sales (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  
  -- 년월 정보
  year INTEGER NOT NULL,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  
  -- 매출 정보
  revenue DECIMAL(15,2) DEFAULT 0,
  cost DECIMAL(15,2) DEFAULT 0,
  profit DECIMAL(15,2) DEFAULT 0,
  
  -- 세부 항목
  management_fee DECIMAL(12,2) DEFAULT 0,
  parking_fee DECIMAL(12,2) DEFAULT 0,
  utility_fee DECIMAL(12,2) DEFAULT 0,
  other_income DECIMAL(12,2) DEFAULT 0,
  
  -- 지출 항목
  labor_cost DECIMAL(12,2) DEFAULT 0,
  utility_cost DECIMAL(12,2) DEFAULT 0,
  maintenance_cost DECIMAL(12,2) DEFAULT 0,
  other_expense DECIMAL(12,2) DEFAULT 0,
  
  -- 메모
  notes TEXT,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 중복 방지 제약
  UNIQUE(apartment_id, year, month)
);

-- ==========================================
-- Phase D: Additional Features
-- ==========================================

-- 5. announcements (공지사항)
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID REFERENCES public.apartments(id) ON DELETE CASCADE,
  
  -- 공지사항 정보
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  category VARCHAR(50) DEFAULT 'general' CHECK (category IN ('general', 'urgent', 'event', 'maintenance', 'notice')),
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high')),
  
  -- 공개 범위
  is_pinned BOOLEAN DEFAULT false,
  
  -- 작성자
  author_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  
  -- 첨부 파일
  attachment_url TEXT,
  attachment_name TEXT,
  
  -- 조회수
  view_count INTEGER DEFAULT 0,
  
  -- 메타데이터
  published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. notifications (알림)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  
  -- 알림 정보
  title VARCHAR(200) NOT NULL,
  message TEXT,
  type VARCHAR(50) DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
  
  -- 링크
  link_url TEXT,
  
  -- 상태
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. work_schedules (근무 일정)
CREATE TABLE IF NOT EXISTS public.work_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  
  -- 일정 정보
  schedule_date DATE NOT NULL,
  shift_type VARCHAR(20) DEFAULT 'day' CHECK (shift_type IN ('day', 'night', 'off', 'holiday')),
  
  -- 시간
  start_time TIME,
  end_time TIME,
  
  -- 메모
  notes TEXT,
  
  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 중복 방지
  UNIQUE(employee_id, schedule_date)
);

-- ==========================================
-- Indexes (성능 최적화)
-- ==========================================

-- monthly_settlements 인덱스
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_apartment_id ON public.monthly_settlements(apartment_id);
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_year_month ON public.monthly_settlements(year_month);
CREATE INDEX IF NOT EXISTS idx_monthly_settlements_status ON public.monthly_settlements(status);

-- payroll_statements 인덱스
CREATE INDEX IF NOT EXISTS idx_payroll_statements_apartment_id ON public.payroll_statements(apartment_id);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_employee_id ON public.payroll_statements(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_year_month ON public.payroll_statements(year_month);
CREATE INDEX IF NOT EXISTS idx_payroll_statements_status ON public.payroll_statements(status);

-- complaints 인덱스
CREATE INDEX IF NOT EXISTS idx_complaints_apartment_id ON public.complaints(apartment_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON public.complaints(priority);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON public.complaints(created_at);
CREATE INDEX IF NOT EXISTS idx_complaints_employee_id ON public.complaints(employee_id);

-- sales 인덱스
CREATE INDEX IF NOT EXISTS idx_sales_apartment_id ON public.sales(apartment_id);
CREATE INDEX IF NOT EXISTS idx_sales_year_month ON public.sales(year, month);
CREATE INDEX IF NOT EXISTS idx_sales_apartment_year_month ON public.sales(apartment_id, year, month);

-- announcements 인덱스
CREATE INDEX IF NOT EXISTS idx_announcements_apartment_id ON public.announcements(apartment_id);
CREATE INDEX IF NOT EXISTS idx_announcements_published_at ON public.announcements(published_at);
CREATE INDEX IF NOT EXISTS idx_announcements_is_pinned ON public.announcements(is_pinned);

-- notifications 인덱스
CREATE INDEX IF NOT EXISTS idx_notifications_employee_id ON public.notifications(employee_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- work_schedules 인덱스
CREATE INDEX IF NOT EXISTS idx_work_schedules_apartment_id ON public.work_schedules(apartment_id);
CREATE INDEX IF NOT EXISTS idx_work_schedules_employee_id ON public.work_schedules(employee_id);
CREATE INDEX IF NOT EXISTS idx_work_schedules_schedule_date ON public.work_schedules(schedule_date);

-- ==========================================
-- RLS (Row Level Security) 활성화
-- ==========================================

ALTER TABLE public.monthly_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_schedules ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- RLS 정책 (개발 환경 - 모든 접근 허용)
-- ==========================================

CREATE POLICY "Enable all access for authenticated users" ON public.monthly_settlements
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.payroll_statements
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.complaints
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.sales
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.announcements
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.notifications
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON public.work_schedules
  FOR ALL USING (true) WITH CHECK (true);

-- ==========================================
-- updated_at 자동 업데이트 트리거
-- ==========================================

-- 트리거 함수 (이미 존재하면 재사용)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_monthly_settlements_updated_at
  BEFORE UPDATE ON public.monthly_settlements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payroll_statements_updated_at
  BEFORE UPDATE ON public.payroll_statements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON public.complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at
  BEFORE UPDATE ON public.sales
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at
  BEFORE UPDATE ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_schedules_updated_at
  BEFORE UPDATE ON public.work_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 완료!
-- ==========================================
-- 총 7개 테이블, 23개 인덱스, 7개 RLS 정책, 6개 트리거 생성 완료
-- 
-- 테이블 목록:
-- 1. monthly_settlements (정산서 관리)
-- 2. payroll_statements (급여명세서)
-- 3. complaints (민원 관리)
-- 4. sales (매출 관리)
-- 5. announcements (공지사항)
-- 6. notifications (알림)
-- 7. work_schedules (근무 일정)
