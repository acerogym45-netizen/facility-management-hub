-- vacations 테이블 완전 재생성 (모든 문제 해결)
-- ⚠️ 주의: 기존 데이터 모두 삭제됨!

-- 1. 기존 테이블 삭제
DROP TABLE IF EXISTS vacations CASCADE;

-- 2. 새 테이블 생성 (정확한 스키마)
CREATE TABLE vacations (
    id BIGSERIAL PRIMARY KEY,
    
    -- 직원 정보
    employee_id UUID NOT NULL,
    employee_name TEXT NOT NULL,
    
    -- 단지 정보
    apartment_id UUID NOT NULL,
    
    -- 휴가 정보 (vacation_date는 사용하지 않음!)
    vacation_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    
    -- 상태
    status TEXT NOT NULL DEFAULT 'pending',
    
    -- 관리자 정보
    admin_comment TEXT,
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 인덱스 생성
CREATE INDEX idx_vacations_employee ON vacations(employee_id);
CREATE INDEX idx_vacations_apartment ON vacations(apartment_id);
CREATE INDEX idx_vacations_status ON vacations(status);
CREATE INDEX idx_vacations_dates ON vacations(start_date, end_date);

-- 4. RLS 비활성화
ALTER TABLE vacations DISABLE ROW LEVEL SECURITY;

-- 5. 완료 메시지
SELECT 
    '✅ vacations 테이블이 완전히 재생성되었습니다!' AS message,
    'RLS: 비활성화' AS rls_status,
    'vacation_date 컬럼: 제거됨' AS fix_status,
    'start_date, end_date: 정상 생성' AS date_columns;
