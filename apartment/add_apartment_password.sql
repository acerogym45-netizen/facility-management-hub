-- apartments 테이블에 password 컬럼 추가
ALTER TABLE apartments 
ADD COLUMN IF NOT EXISTS password TEXT DEFAULT 'bdxi2026';

-- 기존 아파트들에 개별 비밀번호 설정 (예시)
-- 실제 사용 시 원하는 비밀번호로 변경 필요

UPDATE apartments SET password = 'bdxi2026' WHERE password IS NULL;

-- 특정 아파트에 개별 비밀번호 설정 예시:
-- UPDATE apartments SET password = 'apt001' WHERE name = 'e편한세상탕정퍼스트드림';
-- UPDATE apartments SET password = 'apt002' WHERE name = '내포이지더원';
-- UPDATE apartments SET password = 'apt003' WHERE name = '상도푸르지오클라베뉴';

-- 비밀번호 확인 쿼리
-- SELECT id, name, password FROM apartments ORDER BY name;
