-- ====================================
-- Holidays 테이블 생성 스크립트
-- Supabase SQL Editor에서 실행하세요
-- ====================================

-- 1. holidays 테이블 생성
CREATE TABLE IF NOT EXISTS public.holidays (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  apartment_id TEXT NOT NULL,
  holiday_date DATE NOT NULL,
  holiday_name TEXT NOT NULL,
  holiday_type TEXT NOT NULL DEFAULT 'national',
  note TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(apartment_id, holiday_date)
);

-- 2. 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_holidays_apartment 
  ON public.holidays(apartment_id);

CREATE INDEX IF NOT EXISTS idx_holidays_date 
  ON public.holidays(holiday_date);

-- 3. RLS (Row Level Security) 활성화
ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 생성 (모든 사용자 접근 허용)
CREATE POLICY "Enable read access for all users" 
  ON public.holidays FOR SELECT 
  USING (true);

CREATE POLICY "Enable insert access for all users" 
  ON public.holidays FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Enable delete access for all users" 
  ON public.holidays FOR DELETE 
  USING (true);

-- 5. 2026년 대한민국 공휴일 샘플 데이터 (선택사항)
-- apartment_id는 실제 단지 ID로 변경하세요
INSERT INTO public.holidays (apartment_id, holiday_date, holiday_name, holiday_type) VALUES
  ('your-apartment-id', '2026-01-01', '신정', 'national'),
  ('your-apartment-id', '2026-02-16', '설날 연휴', 'national'),
  ('your-apartment-id', '2026-02-17', '설날', 'national'),
  ('your-apartment-id', '2026-02-18', '설날 연휴', 'national'),
  ('your-apartment-id', '2026-03-01', '삼일절', 'national'),
  ('your-apartment-id', '2026-05-05', '어린이날', 'national'),
  ('your-apartment-id', '2026-05-25', '석가탄신일', 'national'),
  ('your-apartment-id', '2026-06-06', '현충일', 'national'),
  ('your-apartment-id', '2026-08-15', '광복절', 'national'),
  ('your-apartment-id', '2026-09-28', '추석 연휴', 'national'),
  ('your-apartment-id', '2026-09-29', '추석', 'national'),
  ('your-apartment-id', '2026-09-30', '추석 연휴', 'national'),
  ('your-apartment-id', '2026-10-03', '개천절', 'national'),
  ('your-apartment-id', '2026-10-09', '한글날', 'national'),
  ('your-apartment-id', '2026-12-25', '크리스마스', 'national')
ON CONFLICT (apartment_id, holiday_date) DO NOTHING;

-- 확인 쿼리
SELECT * FROM public.holidays ORDER BY holiday_date;
