-- ==========================================
-- 📊 월간 정산서 시스템 데이터베이스 스키마
-- ==========================================
-- 작성일: 2026-05-11
-- 목적: 단지별 월간 정산서 제출 및 승인 시스템
-- ==========================================

-- ==========================================
-- 1. 월간 정산서 테이블
-- ==========================================

CREATE TABLE IF NOT EXISTS monthly_settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 단지 정보
  apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE,
  apartment_name TEXT NOT NULL, -- 단지명 저장 (조인 최소화)
  
  -- 정산 기간
  year_month TEXT NOT NULL, -- 'YYYY-MM' 형식 (예: '2026-05')
  start_date DATE NOT NULL, -- 2026-05-01
  end_date DATE NOT NULL,   -- 2026-05-31
  
  -- 제출 정보
  submitted_by UUID REFERENCES employees(id),
  submitted_by_name TEXT, -- 제출자 이름 저장
  submitted_at TIMESTAMP WITH TIME ZONE,
  
  -- 파일 정보
  excel_file_url TEXT, -- Supabase Storage URL
  file_name TEXT,
  file_size BIGINT, -- bytes
  
  -- 상태 관리
  status TEXT NOT NULL DEFAULT 'draft' CHECK (
    status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'revised')
  ),
  -- draft: 초안 작성 중
  -- submitted: 본사 제출 완료
  -- under_review: 검토 중
  -- approved: 승인 완료
  -- rejected: 반려
  -- revised: 수정 후 재제출
  
  -- 승인/반려 정보
  reviewed_by UUID, -- 마스터 관리자 ID (employees 테이블과 별도)
  reviewed_by_name TEXT, -- 검토자 이름
  reviewed_at TIMESTAMP WITH TIME ZONE,
  review_comment TEXT, -- 승인/반려 코멘트
  
  -- 자동 집계 통계
  total_employees INTEGER DEFAULT 0, -- 총 직원 수
  total_work_days INTEGER DEFAULT 0, -- 총 근무 일수
  total_work_hours DECIMAL(10, 2) DEFAULT 0, -- 총 근무 시간
  total_overtime_hours DECIMAL(10, 2) DEFAULT 0, -- 총 초과 근무
  total_late_count INTEGER DEFAULT 0, -- 총 지각 횟수
  total_absent_count INTEGER DEFAULT 0, -- 총 결근 횟수
  total_salary DECIMAL(15, 2) DEFAULT 0, -- 총 급여 합계
  
  -- 메타데이터
  notes TEXT, -- 특이사항 및 메모
  manager_comment TEXT, -- 단지 관리자 코멘트
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 유니크 제약: 단지당 월별 1개 정산서만
  UNIQUE(apartment_id, year_month)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_settlements_apartment 
  ON monthly_settlements(apartment_id);

CREATE INDEX IF NOT EXISTS idx_settlements_year_month 
  ON monthly_settlements(year_month);

CREATE INDEX IF NOT EXISTS idx_settlements_status 
  ON monthly_settlements(status);

CREATE INDEX IF NOT EXISTS idx_settlements_submitted_at 
  ON monthly_settlements(submitted_at);

CREATE INDEX IF NOT EXISTS idx_settlements_reviewed_at 
  ON monthly_settlements(reviewed_at);

-- 복합 인덱스: 상태별 최신순 조회
CREATE INDEX IF NOT EXISTS idx_settlements_status_submitted 
  ON monthly_settlements(status, submitted_at DESC);

-- 코멘트 추가
COMMENT ON TABLE monthly_settlements IS '단지별 월간 정산서 관리 테이블';
COMMENT ON COLUMN monthly_settlements.year_month IS '정산 연월 (YYYY-MM 형식)';
COMMENT ON COLUMN monthly_settlements.status IS 'draft/submitted/under_review/approved/rejected/revised';
COMMENT ON COLUMN monthly_settlements.total_salary IS '총 급여 합계 (원)';

-- ==========================================
-- 2. 정산서 이력 테이블
-- ==========================================

CREATE TABLE IF NOT EXISTS settlement_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  settlement_id UUID REFERENCES monthly_settlements(id) ON DELETE CASCADE,
  
  -- 액션 정보
  action TEXT NOT NULL CHECK (
    action IN ('created', 'saved', 'submitted', 'under_review', 'approved', 'rejected', 'revised', 'downloaded', 'commented')
  ),
  -- created: 정산서 생성
  -- saved: 임시 저장
  -- submitted: 본사 제출
  -- under_review: 검토 시작
  -- approved: 승인
  -- rejected: 반려
  -- revised: 수정 후 재제출
  -- downloaded: 다운로드
  -- commented: 코멘트 추가
  
  -- 수행자 정보
  actor_id UUID, -- employees.id 또는 마스터 관리자 ID
  actor_name TEXT NOT NULL,
  actor_role TEXT NOT NULL, -- 'apartment_admin', 'master_admin'
  
  -- 상태 변경
  previous_status TEXT,
  new_status TEXT,
  
  -- 코멘트
  comment TEXT,
  
  -- 추가 메타데이터
  metadata JSONB, -- 유연한 추가 정보 저장
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_settlement_logs_settlement 
  ON settlement_logs(settlement_id);

CREATE INDEX IF NOT EXISTS idx_settlement_logs_created 
  ON settlement_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_settlement_logs_actor 
  ON settlement_logs(actor_id);

CREATE INDEX IF NOT EXISTS idx_settlement_logs_action 
  ON settlement_logs(action);

-- 코멘트 추가
COMMENT ON TABLE settlement_logs IS '정산서 변경 이력 및 감사 로그';
COMMENT ON COLUMN settlement_logs.action IS '수행된 액션 타입';
COMMENT ON COLUMN settlement_logs.actor_role IS '수행자 역할 (apartment_admin/master_admin)';

-- ==========================================
-- 3. 정산서 첨부 파일 테이블 (선택사항)
-- ==========================================

CREATE TABLE IF NOT EXISTS settlement_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  settlement_id UUID REFERENCES monthly_settlements(id) ON DELETE CASCADE,
  
  -- 파일 정보
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT, -- 'excel', 'pdf', 'image', 'document'
  file_size BIGINT, -- bytes
  
  -- 메타데이터
  description TEXT,
  uploaded_by UUID REFERENCES employees(id),
  uploaded_by_name TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_attachments_settlement 
  ON settlement_attachments(settlement_id);

CREATE INDEX IF NOT EXISTS idx_attachments_uploaded 
  ON settlement_attachments(uploaded_by);

-- 코멘트 추가
COMMENT ON TABLE settlement_attachments IS '정산서 관련 첨부 파일';

-- ==========================================
-- 4. RLS (Row Level Security) 정책
-- ==========================================

-- RLS 활성화
ALTER TABLE monthly_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlement_attachments ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 4-1. monthly_settlements RLS 정책
-- ==========================================

-- 🔒 단지 관리자: 자신의 단지 정산서만 조회
CREATE POLICY "Apartment admins view own settlements"
ON monthly_settlements FOR SELECT
USING (
  apartment_id IN (
    SELECT apartment_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND is_active = true
  )
);

-- 🔒 단지 관리자: 자신의 단지 정산서 생성
CREATE POLICY "Apartment admins create own settlements"
ON monthly_settlements FOR INSERT
WITH CHECK (
  apartment_id IN (
    SELECT apartment_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND is_active = true
  )
);

-- 🔒 단지 관리자: 자신의 단지 정산서 수정 (draft, rejected 상태만)
CREATE POLICY "Apartment admins update own settlements"
ON monthly_settlements FOR UPDATE
USING (
  apartment_id IN (
    SELECT apartment_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND is_active = true
  )
  AND status IN ('draft', 'rejected', 'revised')
);

-- 🔒 단지 관리자: 자신의 단지 정산서 삭제 (draft 상태만)
CREATE POLICY "Apartment admins delete own drafts"
ON monthly_settlements FOR DELETE
USING (
  apartment_id IN (
    SELECT apartment_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND is_active = true
  )
  AND status = 'draft'
);

-- 🔐 마스터 관리자: 모든 정산서 전체 권한
-- Note: 마스터 관리자는 별도 인증 시스템 사용 예정
-- 임시로 role='master_admin' 체크
CREATE POLICY "Master admin full access settlements"
ON monthly_settlements FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees 
    WHERE id = auth.uid() 
    AND role = 'master_admin'
  )
);

-- ==========================================
-- 4-2. settlement_logs RLS 정책
-- ==========================================

-- 🔒 단지 관리자: 자신의 단지 로그만 조회
CREATE POLICY "Apartment admins view own logs"
ON settlement_logs FOR SELECT
USING (
  settlement_id IN (
    SELECT id FROM monthly_settlements
    WHERE apartment_id IN (
      SELECT apartment_id 
      FROM employees 
      WHERE id = auth.uid()
    )
  )
);

-- 🔒 단지 관리자: 로그 생성 (시스템이 자동으로 생성)
CREATE POLICY "Apartment admins create logs"
ON settlement_logs FOR INSERT
WITH CHECK (
  settlement_id IN (
    SELECT id FROM monthly_settlements
    WHERE apartment_id IN (
      SELECT apartment_id 
      FROM employees 
      WHERE id = auth.uid()
    )
  )
);

-- 🔐 마스터 관리자: 모든 로그 조회 및 생성
CREATE POLICY "Master admin full access logs"
ON settlement_logs FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees 
    WHERE id = auth.uid() 
    AND role = 'master_admin'
  )
);

-- ==========================================
-- 4-3. settlement_attachments RLS 정책
-- ==========================================

-- 🔒 단지 관리자: 자신의 단지 첨부파일만 조회
CREATE POLICY "Apartment admins view own attachments"
ON settlement_attachments FOR SELECT
USING (
  settlement_id IN (
    SELECT id FROM monthly_settlements
    WHERE apartment_id IN (
      SELECT apartment_id 
      FROM employees 
      WHERE id = auth.uid()
    )
  )
);

-- 🔒 단지 관리자: 첨부파일 업로드
CREATE POLICY "Apartment admins upload attachments"
ON settlement_attachments FOR INSERT
WITH CHECK (
  settlement_id IN (
    SELECT id FROM monthly_settlements
    WHERE apartment_id IN (
      SELECT apartment_id 
      FROM employees 
      WHERE id = auth.uid()
    )
  )
);

-- 🔒 단지 관리자: 첨부파일 삭제
CREATE POLICY "Apartment admins delete attachments"
ON settlement_attachments FOR DELETE
USING (
  settlement_id IN (
    SELECT id FROM monthly_settlements
    WHERE apartment_id IN (
      SELECT apartment_id 
      FROM employees 
      WHERE id = auth.uid()
    )
    AND status IN ('draft', 'rejected')
  )
);

-- 🔐 마스터 관리자: 모든 첨부파일 전체 권한
CREATE POLICY "Master admin full access attachments"
ON settlement_attachments FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM employees 
    WHERE id = auth.uid() 
    AND role = 'master_admin'
  )
);

-- ==========================================
-- 5. 트리거: 자동 updated_at 업데이트
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_settlements_updated_at ON monthly_settlements;
CREATE TRIGGER update_settlements_updated_at
  BEFORE UPDATE ON monthly_settlements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 6. 트리거: 자동 로그 생성
-- ==========================================

CREATE OR REPLACE FUNCTION log_settlement_changes()
RETURNS TRIGGER AS $$
DECLARE
  v_actor_name TEXT;
  v_actor_role TEXT;
BEGIN
  -- 현재 사용자 정보 가져오기
  SELECT name, role INTO v_actor_name, v_actor_role
  FROM employees
  WHERE id = auth.uid();
  
  -- INSERT: 생성 로그
  IF TG_OP = 'INSERT' THEN
    INSERT INTO settlement_logs (
      settlement_id,
      action,
      actor_id,
      actor_name,
      actor_role,
      previous_status,
      new_status,
      comment
    ) VALUES (
      NEW.id,
      'created',
      auth.uid(),
      COALESCE(v_actor_name, '시스템'),
      COALESCE(v_actor_role, 'system'),
      NULL,
      NEW.status,
      '정산서 생성'
    );
  
  -- UPDATE: 상태 변경 로그
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO settlement_logs (
      settlement_id,
      action,
      actor_id,
      actor_name,
      actor_role,
      previous_status,
      new_status,
      comment
    ) VALUES (
      NEW.id,
      NEW.status, -- action = new status
      auth.uid(),
      COALESCE(v_actor_name, '시스템'),
      COALESCE(v_actor_role, 'system'),
      OLD.status,
      NEW.status,
      CASE 
        WHEN NEW.status = 'submitted' THEN '본사에 제출'
        WHEN NEW.status = 'approved' THEN '승인 완료'
        WHEN NEW.status = 'rejected' THEN '반려: ' || COALESCE(NEW.review_comment, '')
        ELSE '상태 변경'
      END
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS log_settlement_changes_trigger ON monthly_settlements;
CREATE TRIGGER log_settlement_changes_trigger
  AFTER INSERT OR UPDATE ON monthly_settlements
  FOR EACH ROW
  EXECUTE FUNCTION log_settlement_changes();

-- ==========================================
-- 7. 헬퍼 함수: 정산서 통계 자동 계산
-- ==========================================

CREATE OR REPLACE FUNCTION calculate_settlement_statistics(
  p_apartment_id UUID,
  p_year_month TEXT
)
RETURNS TABLE (
  total_employees INTEGER,
  total_work_days INTEGER,
  total_work_hours DECIMAL,
  total_overtime_hours DECIMAL,
  total_late_count INTEGER,
  total_absent_count INTEGER
) AS $$
DECLARE
  v_start_date DATE;
  v_end_date DATE;
BEGIN
  -- 연월을 날짜로 변환
  v_start_date := (p_year_month || '-01')::DATE;
  v_end_date := (DATE_TRUNC('month', v_start_date) + INTERVAL '1 month - 1 day')::DATE;
  
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT e.id)::INTEGER as total_employees,
    COUNT(DISTINCT DATE(a.check_in_time))::INTEGER as total_work_days,
    COALESCE(SUM(
      EXTRACT(EPOCH FROM (a.check_out_time - a.check_in_time)) / 3600
    ), 0)::DECIMAL as total_work_hours,
    COALESCE(SUM(a.overtime_hours), 0)::DECIMAL as total_overtime_hours,
    COALESCE(SUM(CASE WHEN a.status = 'late' THEN 1 ELSE 0 END), 0)::INTEGER as total_late_count,
    COALESCE(SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0)::INTEGER as total_absent_count
  FROM employees e
  LEFT JOIN attendance a ON a.employee_id = e.id 
    AND DATE(a.check_in_time) BETWEEN v_start_date AND v_end_date
  WHERE e.apartment_id = p_apartment_id
    AND e.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- 사용 예시:
-- SELECT * FROM calculate_settlement_statistics(
--   'apartment-uuid',
--   '2026-05'
-- );

-- ==========================================
-- 8. Supabase Storage 버킷 설정
-- ==========================================

-- Note: 이 부분은 Supabase Dashboard에서 수동으로 생성 필요

/*
버킷명: monthly-settlements
설정:
  - Public: No (Private)
  - File size limit: 50MB
  - Allowed MIME types: 
    - application/vnd.openxmlformats-officedocument.spreadsheetml.sheet (.xlsx)
    - application/vnd.ms-excel (.xls)
    - application/pdf

RLS 정책 (Storage):
1. 단지 관리자: 자신의 단지 폴더에만 업로드
   - Path pattern: {apartment_id}/*
   
2. 단지 관리자: 자신의 단지 파일만 다운로드
   - Path pattern: {apartment_id}/*
   
3. 마스터 관리자: 모든 파일 접근
*/

-- ==========================================
-- 9. 샘플 데이터 (개발/테스트용)
-- ==========================================

-- 샘플 정산서 생성 (주석 처리)
/*
INSERT INTO monthly_settlements (
  apartment_id,
  apartment_name,
  year_month,
  start_date,
  end_date,
  submitted_by_name,
  status,
  total_employees,
  total_work_days,
  total_work_hours,
  total_salary,
  manager_comment
) VALUES (
  'apartment-uuid-1',
  '카인드원 아파트',
  '2026-05',
  '2026-05-01',
  '2026-05-31',
  '김철수',
  'draft',
  15,
  22,
  2640,
  45000000,
  '전반적으로 양호한 근무 태도'
);
*/

-- ==========================================
-- ✅ 스크립트 실행 완료
-- ==========================================

-- 생성된 테이블 확인
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('monthly_settlements', 'settlement_logs', 'settlement_attachments')
ORDER BY table_name;

-- 생성된 인덱스 확인
SELECT 
  indexname,
  tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('monthly_settlements', 'settlement_logs', 'settlement_attachments')
ORDER BY tablename, indexname;

-- 생성된 트리거 확인
SELECT 
  trigger_name,
  event_object_table as table_name,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('monthly_settlements', 'settlement_logs', 'settlement_attachments')
ORDER BY event_object_table, trigger_name;

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE '✅ 월간 정산서 시스템 데이터베이스 스키마 생성 완료!';
  RAISE NOTICE '📋 생성된 테이블: monthly_settlements, settlement_logs, settlement_attachments';
  RAISE NOTICE '🔐 RLS 정책 설정 완료';
  RAISE NOTICE '⚙️ 트리거 및 함수 생성 완료';
  RAISE NOTICE '';
  RAISE NOTICE '📌 다음 단계:';
  RAISE NOTICE '1. Supabase Storage에서 "monthly-settlements" 버킷 생성';
  RAISE NOTICE '2. index.html에 정산서 관리 탭 추가';
  RAISE NOTICE '3. master_dashboard.html에 승인 기능 추가';
END $$;
