#!/bin/bash

# ============================================================
# 자동 진단 스크립트 (Automatic Diagnostic Script)
# ============================================================
# 
# 목적: 코드 레벨에서 잠재적 문제 자동 탐지
# 실행: chmod +x DIAGNOSE.sh && ./DIAGNOSE.sh
#
# ============================================================

echo "🔍 서류 관리 시스템 자동 진단 시작..."
echo "=================================================="
echo ""

ERRORS=0
WARNINGS=0

# 1. submitDocumentUpload 함수 검증
echo "📝 [TEST 1] submitDocumentUpload 함수 검증"
echo "---"

# event 파라미터 확인
if grep -q "submitDocumentUpload = async function(event)" index.html; then
    echo "✅ PASS: event 파라미터 존재"
else
    echo "❌ FAIL: event 파라미터 누락"
    ((ERRORS++))
fi

# Optional chaining 확인
if grep -A 20 "submitDocumentUpload = async function" index.html | grep -q "getElementById.*)?\."; then
    echo "✅ PASS: Optional chaining 사용"
else
    echo "⚠️  WARN: Optional chaining 미사용 (안전성 저하)"
    ((WARNINGS++))
fi

# 로깅 확인
LOG_COUNT=$(grep -A 100 "submitDocumentUpload = async function" index.html | grep -c "console.log")
if [ "$LOG_COUNT" -ge 4 ]; then
    echo "✅ PASS: 충분한 로깅 ($LOG_COUNT개)"
else
    echo "⚠️  WARN: 로깅 부족 ($LOG_COUNT개, 권장 4개 이상)"
    ((WARNINGS++))
fi

echo ""

# 2. 테이블 참조 검증
echo "📊 [TEST 2] 테이블 참조 검증"
echo "---"

DOC_COUNT=$(grep -o "from('documents')" index.html | wc -l)
TEMPLATE_COUNT=$(grep -o "from('document_templates')" index.html | grep -v "popular" | wc -l)

echo "✅ documents 참조: $DOC_COUNT개"
if [ "$TEMPLATE_COUNT" -gt 0 ]; then
    echo "❌ FAIL: document_templates 참조 발견 ($TEMPLATE_COUNT개)"
    echo "   변경 필요: from('document_templates') → from('documents')"
    ((ERRORS++))
else
    echo "✅ PASS: document_templates 참조 없음"
fi

# VIEW 참조 확인 (정상)
VIEW_COUNT=$(grep -o "from('document_templates_popular')" index.html | wc -l)
if [ "$VIEW_COUNT" -gt 0 ]; then
    echo "⚠️  INFO: document_templates_popular VIEW 참조 ($VIEW_COUNT개)"
    echo "   → QUICK_FIX_VIEW.sql 실행 권장"
fi

echo ""

# 3. onclick 속성 검증
echo "🖱️  [TEST 3] 버튼 이벤트 핸들러 검증"
echo "---"

if grep -q 'onclick="app.submitDocumentUpload(event)"' index.html; then
    echo "✅ PASS: event 파라미터 전달"
else
    echo "❌ FAIL: event 파라미터 미전달"
    echo "   수정 필요: onclick=\"app.submitDocumentUpload(event)\""
    ((ERRORS++))
fi

echo ""

# 4. RLS SQL 스크립트 검증
echo "🔒 [TEST 4] RLS 스크립트 검증"
echo "---"

if [ -f "database/FIX_RLS_ANON_ACCESS.sql" ]; then
    echo "✅ PASS: FIX_RLS_ANON_ACCESS.sql 존재"
    
    # DROP POLICY 확인
    DROP_COUNT=$(grep -c "DROP POLICY IF EXISTS" database/FIX_RLS_ANON_ACCESS.sql)
    if [ "$DROP_COUNT" -ge 10 ]; then
        echo "✅ PASS: DROP POLICY 구문 충분 ($DROP_COUNT개)"
    else
        echo "⚠️  WARN: DROP POLICY 구문 부족 ($DROP_COUNT개)"
        ((WARNINGS++))
    fi
    
    # WITH CHECK (true) 확인
    TRUE_COUNT=$(grep -c "WITH CHECK (true)" database/FIX_RLS_ANON_ACCESS.sql)
    if [ "$TRUE_COUNT" -ge 5 ]; then
        echo "✅ PASS: 무제한 정책 충분 ($TRUE_COUNT개)"
    else
        echo "❌ FAIL: 무제한 정책 부족 ($TRUE_COUNT개)"
        ((ERRORS++))
    fi
else
    echo "❌ FAIL: FIX_RLS_ANON_ACCESS.sql 없음"
    ((ERRORS++))
fi

echo ""

# 5. apartment_id 의존성 검증
echo "🏢 [TEST 5] apartment_id 의존성 검증 (문서 시스템)"
echo "---"

# 문서 관련 함수에서 apartment_id 사용 확인
if grep -A 50 "loadDocuments = async function" index.html | grep -q "apartment_id"; then
    echo "⚠️  WARN: loadDocuments에서 apartment_id 사용"
    echo "   → 문서 시스템에서 제거 권장"
    ((WARNINGS++))
else
    echo "✅ PASS: loadDocuments에 apartment_id 없음"
fi

if grep -A 100 "submitDocumentUpload = async function" index.html | grep -q "apartment_id"; then
    echo "⚠️  WARN: submitDocumentUpload에서 apartment_id 사용"
    ((WARNINGS++))
else
    echo "✅ PASS: submitDocumentUpload에 apartment_id 없음"
fi

echo ""

# 6. 카테고리 관리 함수 검증
echo "📁 [TEST 6] 카테고리 관리 함수 검증"
echo "---"

REQUIRED_FUNCS=("toggleCategoryForm" "submitCategoryForm" "editCategory" "deleteCategory" "loadDocumentCategories")
for func in "${REQUIRED_FUNCS[@]}"; do
    if grep -q "$func = async function\|$func = function" index.html; then
        echo "✅ $func 존재"
    else
        echo "❌ $func 누락"
        ((ERRORS++))
    fi
done

echo ""

# 7. 에러 핸들링 검증
echo "⚠️  [TEST 7] 에러 핸들링 검증"
echo "---"

if grep -A 100 "submitDocumentUpload = async function" index.html | grep -q "try {"; then
    echo "✅ PASS: try-catch 블록 존재"
else
    echo "❌ FAIL: try-catch 블록 없음"
    ((ERRORS++))
fi

# 롤백 로직 확인
if grep -A 100 "submitDocumentUpload = async function" index.html | grep -q ".remove(\[fileName\])"; then
    echo "✅ PASS: 파일 롤백 로직 존재"
else
    echo "⚠️  WARN: 파일 롤백 로직 없음"
    ((WARNINGS++))
fi

echo ""

# 8. SQL 파일 존재 확인
echo "📄 [TEST 8] 필수 SQL 파일 확인"
echo "---"

SQL_FILES=("SIMPLE_TABLE_SETUP.sql" "FIX_RLS_ANON_ACCESS.sql")
for file in "${SQL_FILES[@]}"; do
    if [ -f "database/$file" ]; then
        echo "✅ $file 존재"
    else
        echo "❌ $file 누락"
        ((ERRORS++))
    fi
done

echo ""

# 9. 테스트 인프라 확인
echo "🧪 [TEST 9] 테스트 인프라 확인"
echo "---"

if [ -f "TEST_DOCUMENTS.sh" ]; then
    echo "✅ TEST_DOCUMENTS.sh 존재"
    if [ -x "TEST_DOCUMENTS.sh" ]; then
        echo "✅ 실행 권한 설정됨"
    else
        echo "⚠️  WARN: 실행 권한 없음 (chmod +x 필요)"
        ((WARNINGS++))
    fi
else
    echo "⚠️  WARN: TEST_DOCUMENTS.sh 없음"
    ((WARNINGS++))
fi

echo ""

# 최종 결과
echo "=================================================="
echo "📊 진단 결과 요약"
echo "=================================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ 완벽함! (Perfect)"
    echo "   - 모든 검사 통과"
    echo "   - 코드 레벨 문제 없음"
    echo ""
    echo "📌 다음 단계:"
    echo "   1. Supabase에서 FIX_RLS_ANON_ACCESS.sql 실행"
    echo "   2. 브라우저 새로고침 (F5)"
    echo "   3. 파일 업로드 테스트"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  경고 있음 (Warnings: $WARNINGS)"
    echo "   - 치명적 오류 없음"
    echo "   - 개선 권장 사항 있음"
    echo ""
    echo "📌 다음 단계:"
    echo "   1. 경고 검토 (선택사항)"
    echo "   2. Supabase에서 FIX_RLS_ANON_ACCESS.sql 실행"
    echo "   3. 브라우저 새로고침 (F5)"
    echo "   4. 파일 업로드 테스트"
    exit 0
else
    echo "❌ 오류 발견 (Errors: $ERRORS, Warnings: $WARNINGS)"
    echo "   - 수정 필요한 문제 존재"
    echo ""
    echo "🔧 해결 방법:"
    echo "   1. 위 오류 메시지 확인"
    echo "   2. 코드 수정"
    echo "   3. 재진단 실행: ./DIAGNOSE.sh"
    exit 1
fi
