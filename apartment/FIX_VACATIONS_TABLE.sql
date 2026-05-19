-- vacations 테이블 재생성 스크립트
-- 휴가 신청 및 관리를 위한 테이블

-- 1단계: 기존 테이블이 있다면 삭제 (주의: 데이터 손실)
DROP TABLE IF EXISTS vacations CASCADE;

-- 2단계: vacations 테이블 생성
CREATE TABLE vacations (
    -- 기본 정보
    id BIGSERIAL PRIMARY KEY,
    
    -- 직원 정보
    employee_id UUID NOT NULL,
    employee_name TEXT NOT NULL,
    
    -- 단지 정보
    apartment_id UUID NOT NULL,
    
    -- 휴가 정보
    vacation_type TEXT NOT NULL CHECK (vacation_type IN ('annual', 'half_day', 'sick', 'personal', 'other')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    
    -- 상태 정보
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    
    -- 관리자 정보
    admin_comment TEXT,
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약 조건
    CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- 3단계: 인덱스 생성
CREATE INDEX idx_vacations_employee ON vacations(employee_id);
CREATE INDEX idx_vacations_apartment ON vacations(apartment_id);
CREATE INDEX idx_vacations_status ON vacations(status);
CREATE INDEX idx_vacations_dates ON vacations(start_date, end_date);
CREATE INDEX idx_vacations_created ON vacations(created_at DESC);

-- 4단계: RLS (Row Level Security) 정책 설정
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 조회 가능
CREATE POLICY "vacations_select_policy" ON vacations
    FOR SELECT
    USING (true);

-- 모든 사용자가 삽입 가능
CREATE POLICY "vacations_insert_policy" ON vacations
    FOR INSERT
    WITH CHECK (true);

-- 모든 사용자가 업데이트 가능
CREATE POLICY "vacations_update_policy" ON vacations
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- 5단계: 코멘트 추가
COMMENT ON TABLE vacations IS '직원 휴가 신청 및 관리 테이블';
COMMENT ON COLUMN vacations.id IS '휴가 신청 ID';
COMMENT ON COLUMN vacations.employee_id IS '직원 UUID (employees.id)';
COMMENT ON COLUMN vacations.employee_name IS '직원 이름';
COMMENT ON COLUMN vacations.apartment_id IS '단지 UUID';
COMMENT ON COLUMN vacations.vacation_type IS '휴가 종류 (annual: 연차, half_day: 반차, sick: 병가, personal: 개인사유, other: 기타)';
COMMENT ON COLUMN vacations.start_date IS '휴가 시작일';
COMMENT ON COLUMN vacations.end_date IS '휴가 종료일';
COMMENT ON COLUMN vacations.reason IS '휴가 사유';
COMMENT ON COLUMN vacations.status IS '승인 상태 (pending: 대기, approved: 승인, rejected: 거절)';
COMMENT ON COLUMN vacations.admin_comment IS '관리자 코멘트';
COMMENT ON COLUMN vacations.approved_by IS '승인/거절한 관리자 이름';
COMMENT ON COLUMN vacations.approved_at IS '승인/거절 일시';

-- 6단계: 테스트 데이터 삽입 (선택사항)
-- INSERT INTO vacations (employee_id, employee_name, apartment_id, vacation_type, start_date, end_date, reason, status)
-- VALUES 
--     ('직원UUID', '홍길동', '단지UUID', 'annual', '2026-05-10', '2026-05-12', '개인 사정', 'pending');

-- 완료 메시지
SELECT '✅ vacations 테이블이 성공적으로 생성되었습니다!' AS message;
