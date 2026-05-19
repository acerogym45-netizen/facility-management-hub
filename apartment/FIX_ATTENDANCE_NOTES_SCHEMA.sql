-- ========================================
-- attendance_notes 테이블 스키마 수정
-- ========================================
-- 목적: bigint → UUID 타입 변경
-- 이유: apartments.id, employees.id가 모두 UUID 타입
-- 날짜: 2026-05-08
-- ========================================

-- 1. 기존 테이블 백업 (안전장치)
CREATE TABLE IF NOT EXISTS attendance_notes_backup AS 
SELECT * FROM attendance_notes;

-- 2. 기존 테이블 삭제
DROP TABLE IF EXISTS attendance_notes;

-- 3. 올바른 스키마로 재생성
CREATE TABLE attendance_notes (
  id BIGSERIAL PRIMARY KEY,
  
  -- UUID 타입으로 수정
  apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  
  -- employee_id는 제거 (employee_name으로 충분)
  employee_name TEXT NOT NULL,
  
  -- 날짜/시간
  note_date DATE NOT NULL,
  note_time TIME NOT NULL,
  
  -- 특이사항 유형
  note_type TEXT NOT NULL CHECK (note_type IN (
    'holiday_work',
    'outside_work_hours', 
    'non_work_day',
    'duplicate_checkin',
    'other'
  )),
  
  -- 사유 (상세 정보 포함)
  reason TEXT NOT NULL,
  
  -- 메타 정보
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by TEXT DEFAULT 'system',
  
  -- 추가 메타데이터 (선택)
  attendance_record_id BIGINT REFERENCES attendance_records(id) ON DELETE SET NULL
);

-- 4. 인덱스 생성 (성능 최적화)
CREATE INDEX idx_attendance_notes_apartment ON attendance_notes(apartment_id);
CREATE INDEX idx_attendance_notes_employee ON attendance_notes(employee_name);
CREATE INDEX idx_attendance_notes_date ON attendance_notes(note_date);
CREATE INDEX idx_attendance_notes_type ON attendance_notes(note_type);
CREATE INDEX idx_attendance_notes_created ON attendance_notes(created_at DESC);

-- 5. RLS (Row Level Security) 활성화
ALTER TABLE attendance_notes ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성
DROP POLICY IF EXISTS "Enable read access for all users" ON attendance_notes;
CREATE POLICY "Enable read access for all users" 
ON attendance_notes FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Enable insert for all users" ON attendance_notes;
CREATE POLICY "Enable insert for all users" 
ON attendance_notes FOR INSERT 
WITH CHECK (true);

DROP POLICY IF EXISTS "Enable delete for all users" ON attendance_notes;
CREATE POLICY "Enable delete for all users" 
ON attendance_notes FOR DELETE 
USING (true);

-- 7. 코멘트 추가
COMMENT ON TABLE attendance_notes IS '특이사항 기록 테이블 (공휴일 출근, 근무시간외 출근 등)';
COMMENT ON COLUMN attendance_notes.apartment_id IS '아파트 ID (UUID)';
COMMENT ON COLUMN attendance_notes.employee_name IS '직원명 (employees.name)';
COMMENT ON COLUMN attendance_notes.note_type IS '특이사항 유형 (holiday_work, outside_work_hours, non_work_day, duplicate_checkin, other)';
COMMENT ON COLUMN attendance_notes.reason IS '사유 (상세 정보 포함, 예: "긴급 청소 [법정공휴일: 어린이날]")';

-- ========================================
-- 마이그레이션 완료
-- ========================================

-- 검증 쿼리
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'attendance_notes'
ORDER BY ordinal_position;
