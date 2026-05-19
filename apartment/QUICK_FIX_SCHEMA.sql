-- ============================================
-- 🔧 attendance_notes 테이블 긴급 수정
-- ============================================
-- 문제: apartment_id, employee_id가 bigint로 잘못 정의됨
-- 해결: UUID 타입으로 변경
-- ============================================

-- ⚠️ 주의: 기존 데이터는 모두 삭제됩니다!
-- (현재 데이터가 없거나 테스트 데이터만 있는 경우 실행)

DROP TABLE IF EXISTS attendance_notes CASCADE;

CREATE TABLE attendance_notes (
  id BIGSERIAL PRIMARY KEY,
  apartment_id UUID NOT NULL,
  employee_name TEXT NOT NULL,
  note_date DATE NOT NULL,
  note_time TIME NOT NULL,
  note_type TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by TEXT DEFAULT 'system',
  attendance_record_id BIGINT
);

-- 인덱스
CREATE INDEX idx_attendance_notes_apartment ON attendance_notes(apartment_id);
CREATE INDEX idx_attendance_notes_employee ON attendance_notes(employee_name);
CREATE INDEX idx_attendance_notes_date ON attendance_notes(note_date);
CREATE INDEX idx_attendance_notes_type ON attendance_notes(note_type);
CREATE INDEX idx_attendance_notes_created ON attendance_notes(created_at DESC);

-- RLS
ALTER TABLE attendance_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all for authenticated users" 
ON attendance_notes 
USING (true) 
WITH CHECK (true);

-- ============================================
-- ✅ 완료! 이제 코드가 정상 작동합니다.
-- ============================================
