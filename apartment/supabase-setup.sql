-- 직원 테이블
CREATE TABLE employees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    employee_number TEXT NOT NULL UNIQUE,
    department TEXT,
    position TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 구역 테이블
CREATE TABLE locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    building TEXT,
    floor TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 출석 기록 테이블
CREATE TABLE attendance_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id UUID REFERENCES employees(id),
    employee_name TEXT NOT NULL,
    location_id UUID REFERENCES locations(id),
    location_name TEXT NOT NULL,
    location_code TEXT NOT NULL,
    scan_time TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    device_info TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 인덱스 생성
CREATE INDEX idx_attendance_employee ON attendance_records(employee_id);
CREATE INDEX idx_attendance_location ON attendance_records(location_id);
CREATE INDEX idx_attendance_time ON attendance_records(scan_time);

-- Row Level Security 활성화
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기/쓰기 가능 (개발용 - 나중에 수정 필요)
CREATE POLICY "Allow all" ON employees FOR ALL USING (true);
CREATE POLICY "Allow all" ON locations FOR ALL USING (true);
CREATE POLICY "Allow all" ON attendance_records FOR ALL USING (true);
