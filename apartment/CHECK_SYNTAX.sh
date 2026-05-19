#!/bin/bash

echo "🔍 JavaScript 문법 오류 체크..."
echo "================================"

# 1. 고립된 점(.) 찾기 (진짜 문법 오류)
echo ""
echo "📝 [TEST 1] 문법 오류 검색 (고립된 체인)"
# }; 직후에 .으로 시작하는 줄이 있으면 오류
ERRORS=$(grep -B1 "^\s*\.\(insert\|select\|from\)" index.html | grep -A1 "^\s*};" | grep "^\s*\.")

if [ -z "$ERRORS" ]; then
    echo "✅ PASS: 고립된 메서드 체인 없음"
else
    echo "❌ FAIL: 함수 종료 후 고립된 코드:"
    echo "$ERRORS"
    exit 1
fi

# 2. 중복 함수 종료 체크
echo ""
echo "📝 [TEST 2] submitDocumentUpload 함수 완결성 체크"
START_LINE=$(grep -n "submitDocumentUpload = async function" index.html | head -1 | cut -d: -f1)
END_LINE=$(grep -n "// 서류 다운로드" index.html | head -1 | cut -d: -f1)

if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
    # 함수 내용 추출
    FUNC_CONTENT=$(sed -n "${START_LINE},${END_LINE}p" index.html)
    
    # }; 카운트
    CLOSE_COUNT=$(echo "$FUNC_CONTENT" | grep -c "^\s*};")
    
    if [ "$CLOSE_COUNT" -eq 1 ]; then
        echo "✅ PASS: 함수 종료 정상 (}; 1개)"
    else
        echo "❌ FAIL: 함수 종료 이상 (}; ${CLOSE_COUNT}개)"
        exit 1
    fi
else
    echo "⚠️  WARN: 함수를 찾을 수 없음"
fi

# 3. 필수 함수 존재 확인
echo ""
echo "📝 [TEST 3] 필수 함수 존재 확인"

REQUIRED_FUNCS=(
    "loadApartments"
    "selectApartment"
    "loadEmployees"
    "submitDocumentUpload"
    "loadDocumentCategories"
)

ALL_OK=true
for func in "${REQUIRED_FUNCS[@]}"; do
    if grep -q "$func.*function" index.html; then
        echo "✅ $func 존재"
    else
        echo "❌ $func 누락"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = false ]; then
    exit 1
fi

# 4. Supabase 클라이언트 초기화 확인
echo ""
echo "📝 [TEST 4] Supabase 클라이언트 확인"

if grep -q "supabase.createClient" index.html; then
    echo "✅ PASS: Supabase 클라이언트 초기화 존재"
else
    echo "❌ FAIL: Supabase 클라이언트 초기화 없음"
    exit 1
fi

# 5. CDN 로드 확인
echo ""
echo "📝 [TEST 5] CDN 스크립트 확인"

CDNS=("tailwindcss" "supabase-js" "fontawesome" "xlsx" "chart.js")
for cdn in "${CDNS[@]}"; do
    if grep -q "$cdn" index.html; then
        echo "✅ $cdn CDN 존재"
    else
        echo "⚠️  WARN: $cdn CDN 누락"
    fi
done

echo ""
echo "================================"
echo "🎉 모든 체크 완료!"
echo ""
echo "📌 다음 단계:"
echo "   1. 브라우저 캐시 완전 삭제 (Ctrl + Shift + Delete)"
echo "   2. 페이지 강제 새로고침 (Ctrl + Shift + R)"
echo "   3. F12 콘솔 확인 (에러 없어야 함)"
echo "   4. 단지 선택 테스트"
echo ""
