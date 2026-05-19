#!/bin/bash
# ============================================================
# 서류 관리 시스템 - 통합 테스트 스크립트
# Document Management System - Integration Test
# ============================================================

echo "🧪 서류 관리 시스템 테스트 시작"
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
PASSED=0
FAILED=0
TOTAL=0

# 테스트 함수
test_case() {
    TOTAL=$((TOTAL + 1))
    echo -e "${BLUE}[TEST $TOTAL]${NC} $1"
}

test_pass() {
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}✅ PASS${NC}: $1"
    echo ""
}

test_fail() {
    FAILED=$((FAILED + 1))
    echo -e "${RED}❌ FAIL${NC}: $1"
    echo ""
}

# ============================================================
# 체크리스트
# ============================================================

echo "📋 사전 확인 체크리스트"
echo "----------------------"
echo ""

read -p "✓ Supabase에서 STEP 1 SQL (테이블 생성) 실행 완료? (y/n): " step1
if [ "$step1" != "y" ]; then
    echo -e "${RED}⚠️  STEP 1 SQL을 먼저 실행하세요!${NC}"
    exit 1
fi

read -p "✓ Supabase에서 STEP 2 SQL (기존 RLS 정책) 실행 완료? (y/n): " step2
if [ "$step2" != "y" ]; then
    echo -e "${RED}⚠️  STEP 2 SQL을 먼저 실행하세요!${NC}"
    exit 1
fi

read -p "✓ Supabase에서 FIX_RLS_ANON_ACCESS.sql 실행 완료? (y/n): " step3
if [ "$step3" != "y" ]; then
    echo -e "${YELLOW}⚠️  FIX_RLS_ANON_ACCESS.sql을 실행하지 않으면 업로드가 실패할 수 있습니다!${NC}"
    read -p "계속 진행하시겠습니까? (y/n): " continue
    if [ "$continue" != "y" ]; then
        exit 1
    fi
fi

read -p "✓ document-templates 스토리지 버킷 생성 완료? (y/n): " bucket
if [ "$bucket" != "y" ]; then
    echo -e "${RED}⚠️  Storage 버킷을 먼저 생성하세요!${NC}"
    echo "   Supabase Dashboard → Storage → Create Bucket"
    echo "   Name: document-templates"
    echo "   Public: Yes"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 사전 확인 완료!${NC}"
echo ""

# ============================================================
# 테스트 시나리오
# ============================================================

echo "🧪 테스트 시나리오 실행"
echo "======================"
echo ""

# 테스트 1: 웹 페이지 접근
test_case "웹 페이지 로드 테스트"
echo "   브라우저에서 웹 애플리케이션을 열고 F12 콘솔을 확인하세요."
read -p "   페이지가 정상적으로 로드되었나요? (y/n): " page_load
if [ "$page_load" = "y" ]; then
    test_pass "페이지 로드 성공"
else
    test_fail "페이지 로드 실패"
fi

# 테스트 2: 서류 관리 탭 이동
test_case "서류 관리 탭 표시 테스트"
read -p "   '서류 관리' 탭이 보이나요? (y/n): " tab_visible
if [ "$tab_visible" = "y" ]; then
    test_pass "서류 관리 탭 표시됨"
else
    test_fail "서류 관리 탭 없음"
    echo "   → index.html의 tab-documents 확인 필요"
fi

# 테스트 3: 카테고리 로드
test_case "카테고리 로드 테스트"
echo "   '카테고리 관리' 버튼을 클릭하세요."
read -p "   6개 기본 카테고리가 표시되나요? (y/n): " categories
if [ "$categories" = "y" ]; then
    test_pass "카테고리 로드 성공"
else
    test_fail "카테고리 로드 실패"
    echo "   → F12 콘솔에서 loadDocumentCategories 에러 확인"
fi

# 테스트 4: 카테고리 추가
test_case "카테고리 생성 테스트"
echo "   '새 카테고리 추가' 버튼을 클릭하고 테스트 카테고리를 생성하세요."
echo "   이름: 테스트, 아이콘: 📁, 색상: 파랑"
read -p "   카테고리가 성공적으로 추가되었나요? (y/n): " cat_add
if [ "$cat_add" = "y" ]; then
    test_pass "카테고리 생성 성공"
else
    test_fail "카테고리 생성 실패"
    echo "   → RLS 정책 확인: document_categories INSERT"
fi

# 테스트 5: 서류 업로드 모달 열기
test_case "서류 업로드 모달 테스트"
echo "   '서류 업로드' 버튼을 클릭하세요."
read -p "   업로드 모달이 열리나요? (y/n): " modal_open
if [ "$modal_open" = "y" ]; then
    test_pass "업로드 모달 열림"
else
    test_fail "업로드 모달 열리지 않음"
    echo "   → openDocumentUploadModal 함수 확인"
fi

# 테스트 6: 파일 선택
test_case "파일 선택 테스트"
echo "   작은 테스트 파일(PDF, DOCX 등)을 선택하세요."
read -p "   파일이 선택되고 미리보기가 표시되나요? (y/n): " file_select
if [ "$file_select" = "y" ]; then
    test_pass "파일 선택 성공"
else
    test_fail "파일 선택 실패"
fi

# 테스트 7: 서류 업로드 (중요!)
test_case "서류 업로드 실행 테스트"
echo "   제목: 테스트 서류"
echo "   카테고리: 기타 (또는 생성한 테스트 카테고리)"
echo "   업로드 버튼 클릭 후 F12 콘솔을 확인하세요."
echo ""
echo "   예상 로그:"
echo "   📤 파일 업로드 시작: documents/..."
echo "   ✅ Storage 업로드 성공"
echo "   🔗 Public URL: ..."
echo "   💾 DB 저장 시도"
echo "   ✅ 서류 업로드 성공"
echo ""
read -p "   업로드가 성공했나요? (y/n): " upload_success
if [ "$upload_success" = "y" ]; then
    test_pass "서류 업로드 성공 🎉"
else
    test_fail "서류 업로드 실패"
    echo ""
    echo "   실패 원인 분석:"
    read -p "   어느 단계에서 실패했나요? (storage/db/other): " fail_stage
    case $fail_stage in
        storage)
            echo "   → Storage 정책 확인 필요"
            echo "   → document-templates 버킷이 public인지 확인"
            ;;
        db)
            echo "   → RLS 정책 확인: documents INSERT"
            echo "   → FIX_RLS_ANON_ACCESS.sql 실행했는지 확인"
            ;;
        other)
            echo "   → F12 콘솔의 정확한 에러 메시지를 확인하세요"
            ;;
    esac
fi

# 테스트 8: 서류 목록 확인
test_case "서류 목록 표시 테스트"
echo "   업로드 모달을 닫고 서류 목록을 확인하세요."
read -p "   업로드한 서류가 목록에 표시되나요? (y/n): " list_display
if [ "$list_display" = "y" ]; then
    test_pass "서류 목록 표시 성공"
else
    test_fail "서류 목록 표시 실패"
    echo "   → loadDocuments 함수 확인"
fi

# 테스트 9: 서류 다운로드
test_case "서류 다운로드 테스트"
echo "   업로드한 서류의 다운로드 버튼을 클릭하세요."
read -p "   파일이 다운로드되나요? (y/n): " download
if [ "$download" = "y" ]; then
    test_pass "서류 다운로드 성공"
else
    test_fail "서류 다운로드 실패"
fi

# ============================================================
# 테스트 결과 요약
# ============================================================

echo ""
echo "================================"
echo "🧪 테스트 결과 요약"
echo "================================"
echo ""
echo -e "총 테스트: ${BLUE}$TOTAL${NC}개"
echo -e "성공: ${GREEN}$PASSED${NC}개"
echo -e "실패: ${RED}$FAILED${NC}개"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 테스트 통과! 서류 관리 시스템이 정상 작동합니다.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  일부 테스트 실패. 위의 실패 원인을 확인하고 수정하세요.${NC}"
    echo ""
    echo "📝 추가 확인 사항:"
    echo "1. Supabase SQL Editor에서 다음 쿼리 실행:"
    echo "   SELECT * FROM document_categories;"
    echo "   SELECT * FROM documents;"
    echo ""
    echo "2. Supabase Dashboard → Storage → document-templates"
    echo "   업로드된 파일이 있는지 확인"
    echo ""
    echo "3. F12 콘솔에서 빨간색 에러 메시지 확인"
    echo ""
    exit 1
fi
