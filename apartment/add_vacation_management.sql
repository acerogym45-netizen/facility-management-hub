-- 휴가 관리 테이블 생성
-- 직원의 휴가 날짜를 기록하고 관리합니다.

-- 1. vacations 테이블 생성
CREATE TABLE IF NOT EXISTS public.vacations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID REFERENCES public.apartments(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
  employee_name TEXT NOT NULL,
  vacation_date DATE NOT NULL,
  vacation_type TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 인덱스 생성 (조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_vacations_apartment ON public.vacations(apartment_id);
CREATE INDEX IF NOT EXISTS idx_vacations_employee ON public.vacations(employee_id);
CREATE INDEX IF NOT EXISTS idx_vacations_date ON public.vacations(vacation_date);
CREATE INDEX IF NOT EXISTS idx_vacations_apartment_date ON public.vacations(apartment_id, vacation_date);

-- 3. 중복 방지를 위한 유니크 제약조건
-- 같은 날짜에 같은 직원의 같은 유형의 휴가는 중복 불가
CREATE UNIQUE INDEX IF NOT EXISTS idx_vacations_unique 
ON public.vacations(apartment_id, employee_id, vacation_date, vacation_type);

-- 4. RLS (Row Level Security) 활성화
ALTER TABLE public.vacations ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성 (개발 중에는 전체 접근 허용, 향후 수정 필요)
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.vacations;
CREATE POLICY "Enable all access for authenticated users"
ON public.vacations
FOR ALL
TO authenticated, anon
USING (true)
WITH CHECK (true);

-- 6. updated_at 자동 업데이트 트리거 함수 (이미 존재하면 재사용)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. updated_at 트리거 적용
DROP TRIGGER IF EXISTS update_vacations_updated_at ON public.vacations;
CREATE TRIGGER update_vacations_updated_at
BEFORE UPDATE ON public.vacations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 8. 테이블 확인 쿼리
SELECT 
  table_name, 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'vacations'
ORDER BY ordinal_position;

-- 9. 샘플 데이터 조회 (데이터가 있다면)
SELECT 
  v.id,
  a.name as apartment_name,
  v.employee_name,
  v.vacation_date,
  v.vacation_type,
  v.note,
  v.created_at
FROM vacations v
LEFT JOIN apartments a ON v.apartment_id = a.id
ORDER BY v.vacation_date DESC
LIMIT 5;
