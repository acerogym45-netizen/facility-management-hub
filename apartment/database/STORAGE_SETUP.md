# 📦 Supabase Storage 설정 가이드

## 목차
1. [버킷 생성](#버킷-생성)
2. [정책 설정](#정책-설정)
3. [CORS 설정](#cors-설정)
4. [파일 업로드 가이드](#파일-업로드-가이드)
5. [보안 설정](#보안-설정)

---

## 버킷 생성

### 1. `document-templates` 버킷

**용도**: 서류 템플릿 파일 저장

**설정**:
- **이름**: `document-templates`
- **Public**: ✅ YES (공개 버킷)
- **File Size Limit**: 50 MB
- **Allowed MIME Types**: 
  - `application/pdf`
  - `application/vnd.openxmlformats-officedocument.wordprocessingml.document` (docx)
  - `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (xlsx)
  - `application/vnd.openxmlformats-officedocument.presentationml.presentation` (pptx)
  - `application/msword` (doc)
  - `application/vnd.ms-excel` (xls)
  - `image/png`
  - `image/jpeg`
  - `image/jpg`

### Supabase Dashboard에서 생성

```
1. Supabase 대시보드 접속
2. Storage 메뉴 클릭
3. "New bucket" 클릭
4. 이름: document-templates
5. Public bucket: ON
6. "Create bucket" 클릭
```

---

## 정책 설정

### RLS (Row Level Security) 정책

#### 정책 1: 공개 읽기 (모든 사용자)

```sql
-- document-templates 버킷 읽기 권한
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'document-templates');
```

**설명**: 모든 사용자가 서류를 다운로드/조회 가능

---

#### 정책 2: 인증된 사용자 업로드

```sql
-- document-templates 버킷 업로드 권한 (인증된 사용자만)
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'document-templates'
  AND (storage.foldername(name))[1] IN ('documents', 'thumbnails')
);
```

**설명**: 
- 로그인한 사용자만 업로드 가능
- `documents/` 또는 `thumbnails/` 폴더에만 업로드

---

#### 정책 3: 관리자만 수정/삭제

```sql
-- document-templates 버킷 수정/삭제 권한 (관리자만)
CREATE POLICY "Admins can update and delete"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'document-templates'
  AND auth.jwt() ->> 'role' = 'admin'
);

CREATE POLICY "Admins can delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'document-templates'
  AND auth.jwt() ->> 'role' = 'admin'
);
```

**설명**: 관리자 권한이 있는 사용자만 파일 수정/삭제 가능

---

## CORS 설정

### CORS 정책 설정

Supabase는 기본적으로 CORS를 지원하지만, 추가 설정이 필요할 수 있습니다.

```sql
-- CORS 정책 확인
SELECT * FROM storage.buckets WHERE name = 'document-templates';
```

**프론트엔드에서 업로드 시 헤더**:

```javascript
const { data, error } = await supabase.storage
  .from('document-templates')
  .upload('documents/filename.pdf', file, {
    cacheControl: '3600',
    upsert: false,
    contentType: 'application/pdf'
  });
```

---

## 파일 업로드 가이드

### 디렉토리 구조

```
document-templates/
├── documents/
│   ├── {uuid}_v1.0.pdf
│   ├── {uuid}_v1.1.pdf
│   └── {uuid}_v2.0.docx
└── thumbnails/
    ├── {uuid}_thumb.png
    └── {uuid}_thumb.jpg
```

**명명 규칙**:
- `{uuid}_v{version}.{ext}` - 원본 파일
- `{uuid}_thumb.{ext}` - 썸네일 (선택 사항)

---

### JavaScript 업로드 예제

```javascript
// 파일 업로드 함수
async function uploadDocument(file, documentId, version) {
  try {
    // 1. 파일 확장자 추출
    const fileExt = file.name.split('.').pop();
    
    // 2. 안전한 파일명 생성
    const fileName = `documents/${documentId}_v${version}.${fileExt}`;
    
    // 3. Supabase Storage에 업로드
    const { data, error } = await supabase.storage
      .from('document-templates')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false,
        contentType: file.type
      });
    
    if (error) throw error;
    
    // 4. 공개 URL 가져오기
    const { data: urlData } = supabase.storage
      .from('document-templates')
      .getPublicUrl(fileName);
    
    return {
      path: data.path,
      url: urlData.publicUrl
    };
    
  } catch (err) {
    console.error('❌ 파일 업로드 실패:', err);
    throw err;
  }
}

// 사용 예제
const result = await uploadDocument(
  fileInput.files[0], 
  'uuid-1234-5678', 
  '1.0'
);

console.log('업로드 완료:', result.url);
```

---

### 썸네일 생성 (선택 사항)

```javascript
// PDF 첫 페이지를 이미지로 변환 (브라우저에서)
async function generateThumbnail(file) {
  // PDF.js 사용
  const pdf = await pdfjsLib.getDocument(URL.createObjectURL(file)).promise;
  const page = await pdf.getPage(1);
  
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  const viewport = page.getViewport({ scale: 0.5 });
  
  canvas.width = viewport.width;
  canvas.height = viewport.height;
  
  await page.render({
    canvasContext: context,
    viewport: viewport
  }).promise;
  
  // Canvas를 Blob으로 변환
  return new Promise((resolve) => {
    canvas.toBlob(resolve, 'image/png');
  });
}

// 썸네일 업로드
const thumbnail = await generateThumbnail(file);
const thumbResult = await supabase.storage
  .from('document-templates')
  .upload(`thumbnails/${documentId}_thumb.png`, thumbnail);
```

---

## 보안 설정

### 1. 파일 크기 제한

```javascript
// 클라이언트 측 검증
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50 MB

if (file.size > MAX_FILE_SIZE) {
  alert('파일 크기는 50MB를 초과할 수 없습니다.');
  return;
}
```

### 2. MIME 타입 검증

```javascript
const ALLOWED_TYPES = [
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/msword',
  'application/vnd.ms-excel',
  'image/png',
  'image/jpeg'
];

if (!ALLOWED_TYPES.includes(file.type)) {
  alert('지원하지 않는 파일 형식입니다.');
  return;
}
```

### 3. 파일명 살균 (Sanitization)

```javascript
function sanitizeFileName(fileName) {
  // 특수 문자 제거
  return fileName
    .replace(/[^a-zA-Z0-9가-힣._-]/g, '_')
    .replace(/_{2,}/g, '_')
    .substring(0, 255);
}
```

### 4. 바이러스 스캔 (선택 사항)

```javascript
// 서버리스 함수에서 VirusTotal API 사용
async function scanFile(fileBuffer) {
  const response = await fetch('https://www.virustotal.com/api/v3/files', {
    method: 'POST',
    headers: {
      'x-apikey': process.env.VIRUSTOTAL_API_KEY
    },
    body: fileBuffer
  });
  
  const result = await response.json();
  return result.data.attributes.last_analysis_stats.malicious === 0;
}
```

---

## 파일 다운로드

### 공개 URL 방식 (추천)

```javascript
// 공개 URL 가져오기
const { data } = supabase.storage
  .from('document-templates')
  .getPublicUrl('documents/file.pdf');

// 브라우저에서 다운로드
window.open(data.publicUrl, '_blank');
```

### 서명된 URL 방식 (임시 링크)

```javascript
// 1시간 동안 유효한 서명된 URL 생성
const { data, error } = await supabase.storage
  .from('document-templates')
  .createSignedUrl('documents/file.pdf', 3600);

if (data) {
  window.open(data.signedUrl, '_blank');
}
```

---

## 모니터링 및 통계

### Storage 사용량 조회

```sql
-- 버킷별 파일 수
SELECT 
  bucket_id,
  COUNT(*) AS file_count,
  SUM(CAST(metadata->>'size' AS BIGINT)) AS total_size_bytes
FROM storage.objects
WHERE bucket_id = 'document-templates'
GROUP BY bucket_id;
```

### 최근 업로드 파일

```sql
-- 최근 업로드된 파일 목록
SELECT 
  name,
  metadata->>'size' AS size,
  created_at,
  updated_at
FROM storage.objects
WHERE bucket_id = 'document-templates'
ORDER BY created_at DESC
LIMIT 10;
```

---

## 백업 및 복구

### 전체 버킷 백업

```bash
# Supabase CLI 사용
supabase storage download document-templates --recursive --output ./backup/

# 복구
supabase storage upload document-templates ./backup/* --recursive
```

---

## 트러블슈팅

### 문제 1: 업로드 실패

**증상**: `403 Forbidden` 또는 `401 Unauthorized`

**해결**:
1. RLS 정책 확인
2. 인증 토큰 유효성 확인
3. 버킷 권한 확인

```javascript
// 디버깅
const { data: { session } } = await supabase.auth.getSession();
console.log('세션:', session);
```

### 문제 2: CORS 에러

**증상**: `CORS policy: No 'Access-Control-Allow-Origin'`

**해결**:
1. Supabase 프로젝트 설정에서 허용된 Origin 확인
2. API 키 확인
3. 헤더 설정 확인

### 문제 3: 파일이 보이지 않음

**증상**: 업로드 성공했지만 목록에 없음

**해결**:
```sql
-- Storage 테이블 직접 확인
SELECT * FROM storage.objects 
WHERE bucket_id = 'document-templates' 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 다음 단계

✅ Phase 2 완료 후:
- [ ] Phase 3: 관리자용 업로드 UI 구현
- [ ] Phase 4: 서류 목록 및 관리 UI
- [ ] Phase 6: 단지 관리자용 아카이브 페이지

---

**작성일**: 2026-05-09  
**버전**: 1.0  
**다음 문서**: [Phase 3 - 관리자 UI 구현](./ADMIN_UI_GUIDE.md)
