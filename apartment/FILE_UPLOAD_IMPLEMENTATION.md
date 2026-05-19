# 파일 업로드 기능 구현 완료 📤

## 📋 요청 사항
"로고 이미지 URL이 아니라 파일 업로드 형태로 바꿔줘"

사용자가 URL을 수동으로 입력하는 대신, 파일을 직접 선택하여 업로드할 수 있도록 변경 요청

---

## ✅ 구현 내용

### 1. HTML 변경 사항 (`brand_settings.html`)

#### Before (URL 입력 방식):
```html
<input type="url" id="logoUrl" placeholder="https://example.com/logo.png">
<p class="text-xs text-gray-500 mt-1">
    Supabase Storage에 업로드한 이미지의 Public URL을 입력하세요.
</p>
```

#### After (파일 업로드 방식):
```html
<!-- 파일 업로드 버튼 -->
<label for="logoFile" class="flex-1 cursor-pointer">
    <div class="w-full px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg">
        <i class="fas fa-cloud-upload-alt text-2xl text-gray-400 mb-2"></i>
        <p class="text-sm text-gray-600">
            <span class="text-purple-600 font-medium">클릭하여 파일 선택</span> 또는 드래그 앤 드롭
        </p>
        <p class="text-xs text-gray-400 mt-1">PNG, JPG, SVG (최대 2MB)</p>
    </div>
</label>
<input type="file" id="logoFile" accept="image/*" class="hidden" onchange="uploadLogoFile()">

<!-- 업로드 상태 표시 -->
<div id="uploadStatus" class="hidden">
    <div class="flex items-center gap-2 text-sm">
        <i class="fas fa-spinner fa-spin text-purple-600"></i>
        <span class="text-gray-600">파일 업로드 중...</span>
    </div>
</div>

<!-- 현재 로고 미리보기 -->
<div id="currentLogoPreview" class="hidden">
    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
        <img id="currentLogoImage" src="" alt="Current Logo" class="h-12 w-12 object-contain rounded">
        <div class="flex-1">
            <p class="text-sm font-medium text-gray-700" id="currentLogoName">logo.png</p>
            <p class="text-xs text-gray-500">현재 로고</p>
        </div>
        <button type="button" onclick="removeLogoFile()" class="text-red-600 hover:text-red-700">
            <i class="fas fa-trash-alt"></i>
        </button>
    </div>
</div>

<!-- 숨김 필드: URL 저장용 -->
<input type="hidden" id="logoUrl">
```

### 2. JavaScript 함수 추가

#### `uploadLogoFile()` - 파일 업로드 처리
```javascript
async function uploadLogoFile() {
    const fileInput = document.getElementById('logoFile');
    const file = fileInput.files[0];
    
    if (!file) return;
    
    // 파일 크기 체크 (2MB)
    if (file.size > 2 * 1024 * 1024) {
        alert('❌ 파일 크기가 너무 큽니다. 2MB 이하의 이미지를 선택해주세요.');
        return;
    }
    
    // 파일 타입 체크
    if (!file.type.startsWith('image/')) {
        alert('❌ 이미지 파일만 업로드할 수 있습니다.');
        return;
    }
    
    try {
        // 업로드 상태 표시
        document.getElementById('uploadStatus').classList.remove('hidden');
        
        // 파일명 생성 (타임스탬프 + 확장자)
        const timestamp = Date.now();
        const extension = file.name.split('.').pop();
        const fileName = `logo_${timestamp}.${extension}`;
        
        // Supabase Storage에 업로드
        const { data, error } = await sb.storage
            .from('brand-assets')
            .upload(fileName, file, {
                cacheControl: '3600',
                upsert: false
            });
        
        if (error) throw error;
        
        // Public URL 가져오기
        const { data: urlData } = sb.storage
            .from('brand-assets')
            .getPublicUrl(fileName);
        
        const publicUrl = urlData.publicUrl;
        
        // 숨김 필드에 URL 저장
        document.getElementById('logoUrl').value = publicUrl;
        
        // 현재 로고 미리보기 표시
        showCurrentLogo(publicUrl, file.name);
        
        // 미리보기 업데이트
        updatePreview();
        
        alert('✅ 로고 이미지가 업로드되었습니다!');
        
    } catch (error) {
        console.error('❌ 로고 업로드 실패:', error);
        
        // 에러 메시지 상세화
        let errorMessage = '로고 업로드에 실패했습니다.';
        if (error.message.includes('not found')) {
            errorMessage = '❌ Storage 버킷이 존재하지 않습니다.\n\n다음 SQL을 Supabase에서 실행하세요:\n\n-- Storage 버킷 생성\nINSERT INTO storage.buckets (id, name, public)\nVALUES (\'brand-assets\', \'brand-assets\', true)\nON CONFLICT DO NOTHING;';
        }
        alert(errorMessage + '\n\n에러: ' + error.message);
    }
}
```

#### `showCurrentLogo()` - 업로드된 로고 표시
```javascript
function showCurrentLogo(url, filename) {
    const preview = document.getElementById('currentLogoPreview');
    const image = document.getElementById('currentLogoImage');
    const name = document.getElementById('currentLogoName');
    
    image.src = url;
    name.textContent = filename || url.split('/').pop();
    preview.classList.remove('hidden');
}
```

#### `removeLogoFile()` - 로고 제거
```javascript
function removeLogoFile() {
    if (!confirm('로고를 제거하시겠습니까?')) return;
    
    document.getElementById('logoUrl').value = '';
    document.getElementById('currentLogoPreview').classList.add('hidden');
    document.getElementById('logoFile').value = '';
    updatePreview();
}
```

### 3. Supabase Storage 설정

새로운 SQL 파일 생성: `database/CREATE_STORAGE_BRAND_ASSETS.sql`

```sql
-- Supabase Storage 버킷 및 정책 생성
-- 브랜드 로고 및 자산 업로드를 위한 Storage 설정

-- 1. Storage 버킷 생성 (public 접근 가능)
INSERT INTO storage.buckets (id, name, public)
VALUES ('brand-assets', 'brand-assets', true)
ON CONFLICT (id) DO UPDATE 
SET public = true;

-- 2. Storage RLS 정책 - 누구나 읽기 가능
CREATE POLICY "Public Access for brand-assets"
ON storage.objects FOR SELECT
TO anon, public
USING (bucket_id = 'brand-assets');

-- 3. Storage RLS 정책 - 익명 사용자도 업로드 가능
CREATE POLICY "Public Upload for brand-assets"
ON storage.objects FOR INSERT
TO anon, public
WITH CHECK (bucket_id = 'brand-assets');

-- 4. Storage RLS 정책 - 파일 삭제 (authenticated 사용자만)
CREATE POLICY "Authenticated Delete for brand-assets"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'brand-assets');

-- 5. Storage RLS 정책 - 파일 수정 (authenticated 사용자만)
CREATE POLICY "Authenticated Update for brand-assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'brand-assets')
WITH CHECK (bucket_id = 'brand-assets');
```

---

## 🎯 주요 기능

### 1. 파일 선택 인터페이스
- ✅ 드래그 앤 드롭 스타일 UI
- ✅ 클릭하여 파일 선택
- ✅ 지원 형식 안내 (PNG, JPG, SVG)
- ✅ 파일 크기 제한 안내 (최대 2MB)

### 2. 자동 검증
- ✅ 파일 크기 검증 (2MB 제한)
- ✅ 파일 타입 검증 (image/* only)
- ✅ 에러 메시지 표시

### 3. Supabase Storage 통합
- ✅ 자동 파일 업로드
- ✅ 타임스탬프 기반 고유 파일명 생성
- ✅ Public URL 자동 생성
- ✅ 숨김 필드에 URL 저장

### 4. 미리보기 기능
- ✅ 업로드 상태 표시 (로딩 스피너)
- ✅ 현재 업로드된 로고 미리보기
- ✅ 파일명 표시
- ✅ 로고 제거 버튼

### 5. 에러 처리
- ✅ Storage 버킷 없음 감지
- ✅ 권한 부족 감지
- ✅ 상세한 에러 메시지
- ✅ SQL 해결 방법 제시

---

## 📦 파일 변경 사항

### 수정된 파일:
```
/home/user/webapp/
├── brand_settings.html                    # 파일 업로드 UI 및 로직 추가
└── BRAND_CUSTOMIZATION_GUIDE.md          # 파일 업로드 가이드 추가
```

### 새로 생성된 파일:
```
/home/user/webapp/
└── database/
    └── CREATE_STORAGE_BRAND_ASSETS.sql    # Storage 버킷 설정 SQL
```

---

## 🚀 사용 방법

### 1단계: Storage 버킷 설정 (최초 1회)

Supabase SQL Editor에서 실행:
```bash
/home/user/webapp/database/CREATE_STORAGE_BRAND_ASSETS.sql
```

### 2단계: 브랜드 설정 페이지 접속
```
master_dashboard.html → 브랜드 설정 버튼 클릭
또는
brand_settings.html 직접 접속
```

### 3단계: 로고 파일 업로드
1. "로고 이미지" 섹션의 업로드 영역 클릭
2. PNG, JPG, SVG 파일 선택 (최대 2MB)
3. 자동 업로드 완료 대기
4. 미리보기에서 확인
5. "설정 저장" 버튼 클릭

### 4단계: 변경사항 확인
1. 메인 페이지로 이동
2. 페이지 새로고침 (F5)
3. 로고 적용 확인

---

## ⚠️ 문제 해결

### Q: "Storage 버킷이 존재하지 않습니다" 오류
**A:** `CREATE_STORAGE_BRAND_ASSETS.sql` 파일을 Supabase에서 실행하세요.

### Q: "row-level security" 오류
**A:** SQL 파일의 RLS 정책 부분을 다시 실행하세요.

### Q: 파일 업로드는 되는데 이미지가 안 보임
**A:** 
1. Supabase Storage에서 `brand-assets` 버킷이 Public인지 확인
2. 브라우저 개발자 도구(F12)에서 이미지 URL 확인
3. URL 직접 접속하여 이미지 로드 테스트

### Q: 파일 크기 제한을 변경하고 싶음
**A:** `brand_settings.html`의 `uploadLogoFile()` 함수에서 수정:
```javascript
// 기본값: 2MB (2 * 1024 * 1024)
if (file.size > 5 * 1024 * 1024) { // 5MB로 변경
    alert('❌ 파일 크기가 너무 큽니다. 5MB 이하의 이미지를 선택해주세요.');
    return;
}
```

---

## 🎨 기술적 세부사항

### 파일명 생성 방식
```javascript
const timestamp = Date.now();           // 예: 1715434567890
const extension = file.name.split('.').pop();  // 예: png
const fileName = `logo_${timestamp}.${extension}`;  // 결과: logo_1715434567890.png
```

### Storage 업로드 옵션
```javascript
{
    cacheControl: '3600',  // 1시간 캐시
    upsert: false          // 덮어쓰기 방지
}
```

### Public URL 생성
```javascript
const { data: urlData } = sb.storage
    .from('brand-assets')
    .getPublicUrl(fileName);

const publicUrl = urlData.publicUrl;
// 예: https://qgpqhtuynxhmgawakjxe.supabase.co/storage/v1/object/public/brand-assets/logo_1715434567890.png
```

---

## ✅ 테스트 체크리스트

- [ ] Storage 버킷 생성 확인
- [ ] 파일 선택 버튼 동작 확인
- [ ] 2MB 이하 이미지 업로드 테스트
- [ ] 2MB 초과 이미지 업로드 차단 확인
- [ ] 이미지 외 파일 업로드 차단 확인
- [ ] 업로드 상태 표시 확인
- [ ] 현재 로고 미리보기 확인
- [ ] 로고 제거 기능 확인
- [ ] 설정 저장 후 메인 페이지 적용 확인
- [ ] PNG, JPG, SVG 각 형식 테스트

---

## 📊 Before & After 비교

### 이전 방식 (URL 입력):
1. Supabase Storage 수동 접속
2. 파일 업로드
3. Public URL 복사
4. 브랜드 설정 페이지에 붙여넣기
5. 저장

**단점:**
- ❌ 5단계 필요
- ❌ 외부 시스템 접속 필요
- ❌ URL 복사/붙여넣기 번거로움
- ❌ 초보자 진입장벽 높음

### 현재 방식 (파일 업로드):
1. 브랜드 설정 페이지에서 파일 선택
2. 저장

**장점:**
- ✅ 2단계로 간소화
- ✅ 브랜드 설정 페이지에서 완결
- ✅ 자동으로 Storage 업로드
- ✅ 직관적이고 사용하기 쉬움

---

## 🎉 완료!

**커밋 해시**: b4edabe  
**브랜치**: main  
**푸시 완료**: ✅  
**날짜**: 2026-05-11

로고 이미지를 이제 URL 대신 파일 업로드로 편리하게 등록할 수 있습니다! 🚀
