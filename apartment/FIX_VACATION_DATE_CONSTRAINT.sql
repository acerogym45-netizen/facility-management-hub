-- vacations 테이블 제약조건 확인 및 삭제
-- "vacation_date" 컬럼이 NOT NULL로 설정되어 있어 오류 발생

-- 1단계: 기존 제약조건 확인
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'vacations'::regclass;

-- 2단계: vacation_date 컬럼이 있는지 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'vacations'
ORDER BY ordinal_position;

-- 3단계: vacation_date 컬럼 삭제 (있는 경우)
ALTER TABLE vacations DROP COLUMN IF EXISTS vacation_date CASCADE;

-- 4단계: 잘못된 제약조건 삭제
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'vacations'::regclass
        AND pg_get_constraintdef(oid) LIKE '%vacation_date%'
    LOOP
        EXECUTE 'ALTER TABLE vacations DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname);
        RAISE NOTICE 'Dropped constraint: %', r.conname;
    END LOOP;
END $$;

-- 5단계: 필수 컬럼 확인 및 추가
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS end_date DATE;

-- 6단계: 완료 메시지
SELECT '✅ vacation_date 제약조건이 제거되었습니다!' AS message;

-- 7단계: 최종 테이블 구조 확인
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'vacations'
ORDER BY ordinal_position;
