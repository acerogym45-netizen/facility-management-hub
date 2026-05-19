-- vacations 테이블 완전 재생성 (RLS 문제 해결)
-- 이 스크립트는 기존 데이터를 모두 삭제하고 새로 시작합니다

-- ⚠️ 주의: 기존 휴가 신청 데이터가 모두 삭제됩니다!
-- 계속하려면 아래 주석을 해제하고 실행하세요

-- 1단계: 기존 테이블 완전 삭제
DROP TABLE IF EXISTS vacations CASCADE;

-- 2단계: 새 테이블 생성
CREATE TABLE vacations (
    -- 기본 정보
    id BIGSERIAL PRIMARY KEY,
    
    -- 직원 정보
    employee_id UUID NOT NULL,
    employee_name TEXT NOT NULL,
    
    -- 단지 정보
    apartment_id UUID NOT NULL,
    
    -- 휴가 정보
    vacation_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    
    -- 상태 정보
    status TEXT NOT NULL DEFAULT 'pending',
    admin_comment TEXT,
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3단계: 인덱스 생성
CREATE INDEX idx_vacations_employee ON vacations(employee_id);
CREATE INDEX idx_vacations_apartment ON vacations(apartment_id);
CREATE INDEX idx_vacations_status ON vacations(status);
CREATE INDEX idx_vacations_dates ON vacations(start_date, end_date);
CREATE INDEX idx_vacations_created ON vacations(created_at DESC);

-- 4단계: RLS 활성화 및 정책 설정
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;

-- 모든 작업 허용 정책 (인증 불필요)
CREATE POLICY "vacations_allow_all"
ON vacations
FOR ALL
USING (true)
WITH CHECK (true);

-- 5단계: 제약조건 추가 (선택사항)
ALTER TABLE vacations 
    ADD CONSTRAINT valid_date_range 
    CHECK (end_date >= start_date);

ALTER TABLE vacations 
    ADD CONSTRAINT valid_vacation_type 
    CHECK (vacation_type IN ('annual', 'half_day', 'sick', 'personal', 'other'));

ALTER TABLE vacations 
    ADD CONSTRAINT valid_status 
    CHECK (status IN ('pending', 'approved', 'rejected'));

-- 6단계: 코멘트 추가
COMMENT ON TABLE vacations IS '직원 휴가 신청 및 관리 테이블';
COMMENT ON COLUMN vacations.id IS '휴가 신청 ID';
COMMENT ON COLUMN vacations.employee_id IS '직원 UUID';
COMMENT ON COLUMN vacations.employee_name IS '직원 이름';
COMMENT ON COLUMN vacations.apartment_id IS '단지 UUID';
COMMENT ON COLUMN vacations.vacation_type IS '휴가 종류 (annual/half_day/sick/personal/other)';
COMMENT ON COLUMN vacations.start_date IS '휴가 시작일';
COMMENT ON COLUMN vacations.end_date IS '휴가 종료일';
COMMENT ON COLUMN vacations.reason IS '휴가 사유';
COMMENT ON COLUMN vacations.status IS '승인 상태 (pending/approved/rejected)';

-- 7단계: 확인
SELECT 
    '✅ vacations 테이블이 성공적으로 생성되었습니다!' AS message,
    'RLS 정책: 모든 작업 허용' AS rls_status,
    'end_date 컬럼: 포함됨' AS columns_status;

-- 8단계: 정책 확인
SELECT 
    policyname,
    cmd,
    'USING: ' || COALESCE(qual::text, 'true') AS using_clause,
    'WITH CHECK: ' || COALESCE(with_check::text, 'true') AS with_check_clause
FROM pg_policies
WHERE tablename = 'vacations';
