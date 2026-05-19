-- 매출 기록 테이블 생성
CREATE TABLE IF NOT EXISTS sales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    UNIQUE(apartment_id, year, month)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_sales_apartment ON sales(apartment_id);
CREATE INDEX IF NOT EXISTS idx_sales_year_month ON sales(year, month);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(year, month, apartment_id);

-- Row Level Security 활성화
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기/쓰기 가능 (개발용)
CREATE POLICY "Allow all" ON sales FOR ALL USING (true);

-- 업데이트 시각 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_sales_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sales_updated_at_trigger
    BEFORE UPDATE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION update_sales_updated_at();

-- 샘플 데이터 (선택사항)
-- INSERT INTO sales (apartment_id, year, month, amount) VALUES
-- ((SELECT id FROM apartments LIMIT 1), 2026, 1, 5000000),
-- ((SELECT id FROM apartments LIMIT 1), 2026, 2, 5500000);

COMMENT ON TABLE sales IS '아파트별 월별 매출 기록';
COMMENT ON COLUMN sales.amount IS '매출액 (원 단위)';
COMMENT ON COLUMN sales.note IS '특이사항 메모';
