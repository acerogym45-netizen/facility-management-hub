# 📚 서류 템플릿 공유 시스템 - 데이터베이스 스키마 문서

## 📋 목차
1. [개요](#개요)
2. [테이블 구조](#테이블-구조)
3. [관계도](#관계도)
4. [인덱스 전략](#인덱스-전략)
5. [트리거 및 자동화](#트리거-및-자동화)
6. [보안 정책 (RLS)](#보안-정책-rls)
7. [사용 예제](#사용-예제)

---

## 개요

### 목적
- 카카오톡 단톡방 대체
- 전문적이고 체계적인 서류 관리
- 버전 관리 및 이력 추적
- 협업 기능 (댓글, 알림)

### 주요 기능
- ✅ 서류 업로드/다운로드
- ✅ 카테고리 및 태그 분류
- ✅ 버전 관리
- ✅ 검색 및 필터링
- ✅ 즐겨찾기
- ✅ 댓글 시스템
- ✅ 읽음/안읽음 체크
- ✅ 다운로드 통계
- ✅ 권한별 접근 제어

---

## 테이블 구조

### 1. `document_categories` - 서류 카테고리

**용도**: 서류 분류 체계

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `name` | VARCHAR(100) | 카테고리 이름 (UNIQUE) |
| `description` | TEXT | 설명 |
| `icon` | VARCHAR(50) | Font Awesome 아이콘 |
| `color` | VARCHAR(20) | 테마 컬러 |
| `display_order` | INTEGER | 정렬 순서 |
| `is_active` | BOOLEAN | 활성 상태 |
| `created_at` | TIMESTAMP | 생성일 |
| `updated_at` | TIMESTAMP | 수정일 |

**기본 카테고리**:
- 계약서 (blue)
- 공지문 (green)
- 회계 (yellow)
- 민원 (red)
- 점검 (purple)
- 기타 (gray)

---

### 2. `document_templates` - 서류 템플릿 (메인)

**용도**: 서류 파일 및 메타데이터

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `title` | VARCHAR(255) | 제목 |
| `description` | TEXT | 설명 |
| `category_id` | UUID | FK → categories |
| `tags` | TEXT[] | 검색용 태그 배열 |
| `file_url` | TEXT | Supabase Storage URL |
| `file_name` | VARCHAR(255) | 원본 파일명 |
| `file_size` | BIGINT | 파일 크기 (bytes) |
| `file_type` | VARCHAR(50) | 확장자 (docx, pdf 등) |
| `mime_type` | VARCHAR(100) | MIME 타입 |
| `thumbnail_url` | TEXT | 썸네일 URL |
| `version` | VARCHAR(20) | 버전 (1.0, 1.1 등) |
| `version_notes` | TEXT | 버전 변경 내역 |
| `is_latest` | BOOLEAN | 최신 버전 여부 |
| `parent_document_id` | UUID | FK → self (이전 버전) |
| `is_public` | BOOLEAN | 전체 공개 여부 |
| `allowed_apartments` | UUID[] | 접근 가능 단지 목록 |
| `required_role` | VARCHAR(50) | 필요 권한 |
| `uploaded_by` | UUID | FK → employees |
| `created_at` | TIMESTAMP | 생성일 |
| `updated_at` | TIMESTAMP | 수정일 |
| `download_count` | INTEGER | 다운로드 횟수 |
| `view_count` | INTEGER | 조회 횟수 |
| `favorite_count` | INTEGER | 즐겨찾기 수 |
| `is_active` | BOOLEAN | 활성 상태 |
| `is_pinned` | BOOLEAN | 상단 고정 |
| `is_featured` | BOOLEAN | 추천 서류 |
| `expires_at` | TIMESTAMP | 만료일 |
| `notify_on_update` | BOOLEAN | 업데이트 시 알림 |

---

### 3. `document_downloads` - 다운로드 이력

**용도**: 다운로드 추적 및 통계

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `document_id` | UUID | FK → templates |
| `apartment_id` | UUID | FK → apartments |
| `downloaded_by` | UUID | FK → employees |
| `downloaded_at` | TIMESTAMP | 다운로드 시각 |
| `ip_address` | INET | IP 주소 |
| `user_agent` | TEXT | User Agent |
| `download_method` | VARCHAR(50) | 다운로드 방법 |

**트리거**: 자동으로 `download_count` 증가

---

### 4. `document_favorites` - 즐겨찾기

**용도**: 사용자별 즐겨찾기 서류

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `document_id` | UUID | FK → templates |
| `apartment_id` | UUID | FK → apartments |
| `employee_id` | UUID | FK → employees |
| `created_at` | TIMESTAMP | 등록일 |

**제약**: `UNIQUE(document_id, apartment_id, employee_id)`

**트리거**: 자동으로 `favorite_count` 증감

---

### 5. `document_views` - 조회 이력 (읽음 체크)

**용도**: 읽음/안읽음 상태 추적

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `document_id` | UUID | FK → templates |
| `apartment_id` | UUID | FK → apartments |
| `viewed_by` | UUID | FK → employees |
| `first_viewed_at` | TIMESTAMP | 최초 조회 시각 |
| `last_viewed_at` | TIMESTAMP | 최근 조회 시각 |
| `view_count` | INTEGER | 조회 횟수 |
| `is_read` | BOOLEAN | 읽음 완료 여부 |
| `read_at` | TIMESTAMP | 읽음 완료 시각 |

**제약**: `UNIQUE(document_id, apartment_id, viewed_by)`

**트리거**: 자동으로 `view_count` 증가

---

### 6. `document_comments` - 댓글

**용도**: 서류에 대한 댓글 및 토론

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `document_id` | UUID | FK → templates |
| `parent_comment_id` | UUID | FK → self (대댓글) |
| `apartment_id` | UUID | FK → apartments |
| `author_id` | UUID | FK → employees |
| `author_name` | VARCHAR(100) | 작성자 이름 (캐시) |
| `author_role` | VARCHAR(50) | 작성자 역할 (캐시) |
| `content` | TEXT | 댓글 내용 |
| `created_at` | TIMESTAMP | 작성일 |
| `updated_at` | TIMESTAMP | 수정일 |
| `is_deleted` | BOOLEAN | 삭제 여부 |
| `is_pinned` | BOOLEAN | 상단 고정 |
| `is_staff_reply` | BOOLEAN | 관리자 답변 |

---

### 7. `document_notifications` - 알림

**용도**: 새 서류, 업데이트, 댓글 등 알림

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | Primary Key |
| `document_id` | UUID | FK → templates |
| `apartment_id` | UUID | FK → apartments |
| `recipient_id` | UUID | FK → employees |
| `notification_type` | VARCHAR(50) | 알림 유형 |
| `title` | VARCHAR(255) | 제목 |
| `message` | TEXT | 메시지 |
| `is_read` | BOOLEAN | 읽음 여부 |
| `read_at` | TIMESTAMP | 읽은 시각 |
| `created_at` | TIMESTAMP | 생성일 |
| `action_url` | TEXT | 클릭 시 이동 URL |

**알림 유형**:
- `new_document`: 새 서류 등록
- `update`: 서류 업데이트
- `comment`: 새 댓글
- `mention`: 멘션

---

## 관계도

```
document_categories (1) ──< (N) document_templates
                                    │
                                    ├──< (N) document_downloads
                                    ├──< (N) document_favorites  
                                    ├──< (N) document_views
                                    ├──< (N) document_comments
                                    └──< (N) document_notifications

document_templates (1) ──< (N) document_templates (버전 체인)

apartments (1) ──< (N) document_downloads
           (1) ──< (N) document_favorites
           (1) ──< (N) document_views
           (1) ──< (N) document_comments
           (1) ──< (N) document_notifications

employees (1) ──< (N) document_templates (업로더)
          (1) ──< (N) document_downloads
          (1) ──< (N) document_favorites
          (1) ──< (N) document_views
          (1) ──< (N) document_comments (작성자)
          (1) ──< (N) document_notifications (수신자)
```

---

## 인덱스 전략

### 성능 최적화를 위한 인덱스

| 테이블 | 인덱스 | 용도 |
|--------|--------|------|
| `document_templates` | `(category_id, created_at DESC)` | 카테고리별 정렬 |
| `document_templates` | `(is_active, is_pinned DESC, created_at DESC)` | 활성 서류 + 고정 정렬 |
| `document_templates` | `(is_latest, category_id)` | 최신 버전 필터링 |
| `document_templates` | GIN `(tags)` | 태그 검색 |
| `document_templates` | GIN `(to_tsvector(...))` | 전문 검색 |
| `document_downloads` | `(document_id, downloaded_at DESC)` | 서류별 다운로드 이력 |
| `document_downloads` | `(apartment_id, downloaded_at DESC)` | 단지별 다운로드 이력 |
| `document_favorites` | `(apartment_id, employee_id, created_at DESC)` | 사용자별 즐겨찾기 |
| `document_views` | `(apartment_id, viewed_by, is_read)` | 안읽은 서류 필터링 |
| `document_comments` | `(document_id, is_deleted, created_at DESC)` | 서류별 댓글 목록 |
| `document_notifications` | `(apartment_id, recipient_id, is_read, created_at DESC)` | 안읽은 알림 조회 |

---

## 트리거 및 자동화

### 1. 다운로드 카운트 자동 증가
```sql
-- document_downloads INSERT 시 자동 실행
UPDATE document_templates 
SET download_count = download_count + 1
WHERE id = NEW.document_id;
```

### 2. 조회수 자동 증가
```sql
-- document_views INSERT 시 자동 실행
UPDATE document_templates 
SET view_count = view_count + 1
WHERE id = NEW.document_id;
```

### 3. 즐겨찾기 카운트 자동 업데이트
```sql
-- document_favorites INSERT 시: +1
-- document_favorites DELETE 시: -1
UPDATE document_templates 
SET favorite_count = favorite_count ± 1
WHERE id = NEW/OLD.document_id;
```

### 4. updated_at 자동 갱신
```sql
-- UPDATE 시 자동으로 updated_at = NOW() 설정
-- 적용 테이블: document_templates, document_categories, document_comments
```

---

## 보안 정책 (RLS)

### Row Level Security 활성화

#### `document_templates`
- **읽기**: 모든 인증된 사용자 (is_active = TRUE)
- **쓰기**: 관리자만 가능

#### `document_downloads`
- **읽기**: 본인 다운로드 이력만
- **쓰기**: 본인 이력만 추가 가능

#### `document_favorites`
- **읽기/쓰기**: 본인 즐겨찾기만

#### `document_views`
- **읽기/쓰기**: 본인 조회 이력만

#### `document_comments`
- **읽기**: 모든 사용자 (삭제되지 않은 댓글)
- **쓰기**: 인증된 사용자
- **수정**: 본인 댓글만

#### `document_notifications`
- **읽기/수정**: 본인 알림만

---

## 사용 예제

### 1. 새 서류 등록
```sql
INSERT INTO document_templates (
  title, description, category_id, tags,
  file_url, file_name, file_size, file_type,
  version, uploaded_by
) VALUES (
  '입주자 표준 계약서',
  '2026년 업데이트 버전',
  (SELECT id FROM document_categories WHERE name = '계약서'),
  ARRAY['입주자', '계약', '필수'],
  'https://storage.url/file.docx',
  '입주자_계약서_v2.0.docx',
  245678,
  'docx',
  '2.0',
  'user-uuid'
);
```

### 2. 카테고리별 최신 서류 조회
```sql
SELECT 
  dt.id,
  dt.title,
  dt.version,
  dt.download_count,
  dc.name AS category_name,
  dc.icon,
  dc.color
FROM document_templates dt
LEFT JOIN document_categories dc ON dt.category_id = dc.id
WHERE 
  dt.is_active = TRUE
  AND dt.is_latest = TRUE
  AND dc.name = '계약서'
ORDER BY dt.is_pinned DESC, dt.created_at DESC;
```

### 3. 서류 검색
```sql
SELECT * FROM search_documents('계약서', NULL, NULL);
```

### 4. 인기 서류 Top 10
```sql
SELECT * FROM document_templates_popular;
```

### 5. 사용자별 안읽은 서류 조회
```sql
SELECT dt.*
FROM document_templates dt
LEFT JOIN document_views dv ON 
  dt.id = dv.document_id 
  AND dv.apartment_id = 'apt-uuid'
  AND dv.viewed_by = 'user-uuid'
WHERE 
  dt.is_active = TRUE
  AND dt.is_latest = TRUE
  AND (dv.is_read = FALSE OR dv.id IS NULL)
ORDER BY dt.created_at DESC;
```

### 6. 즐겨찾기 추가
```sql
INSERT INTO document_favorites (
  document_id, apartment_id, employee_id
) VALUES (
  'doc-uuid', 'apt-uuid', 'user-uuid'
)
ON CONFLICT DO NOTHING;
```

### 7. 댓글 작성
```sql
INSERT INTO document_comments (
  document_id, apartment_id, author_id,
  author_name, author_role, content
) VALUES (
  'doc-uuid', 'apt-uuid', 'user-uuid',
  '김관리', '관리소장', '이 서류 정말 유용하네요!'
);
```

### 8. 다운로드 이력 기록
```sql
INSERT INTO document_downloads (
  document_id, apartment_id, downloaded_by,
  ip_address, user_agent
) VALUES (
  'doc-uuid', 'apt-uuid', 'user-uuid',
  '192.168.1.1', 'Mozilla/5.0...'
);
-- 자동으로 download_count 증가됨 (트리거)
```

---

## 추가 기능 아이디어

### Phase 2 확장
- [ ] 서류 승인 워크플로우
- [ ] 서류 공유 링크 (임시 URL)
- [ ] 서류 비교 (버전 간 차이)
- [ ] 자동 OCR (PDF 텍스트 추출)
- [ ] 서류 템플릿 (빈칸 채우기)

### Phase 3 고도화
- [ ] AI 서류 요약
- [ ] 서류 추천 시스템
- [ ] 협업 편집 (실시간)
- [ ] 전자 서명
- [ ] 블록체인 인증

---

## 마이그레이션 가이드

### 스키마 적용 방법

1. **Supabase 대시보드**
   - SQL Editor 접속
   - `document_system_schema.sql` 파일 내용 붙여넣기
   - 실행 (Run)

2. **CLI 사용**
   ```bash
   psql -h db.supabase.co -p 5432 -U postgres -d postgres -f document_system_schema.sql
   ```

3. **확인**
   ```sql
   -- 테이블 확인
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name LIKE 'document%';
   
   -- 트리거 확인
   SELECT trigger_name FROM information_schema.triggers
   WHERE trigger_name LIKE '%document%';
   ```

---

## 문의 및 지원

- **작성일**: 2026-05-09
- **버전**: 1.0
- **업데이트**: Phase별 구현 진행 중

---

**다음 단계**: [Phase 2 - Supabase Storage 설정](./STORAGE_SETUP.md)
