/**
 * 통합 시설 관리 플랫폼 - 공통 설정
 * 모든 서브 시스템에서 공유하는 Supabase 설정
 */

// Supabase 설정
const SHARED_SUPABASE_URL = 'https://awqatgkfrzusbidzosrx.supabase.co';
const SHARED_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cWF0Z2tmcnp1c2JpZHpvc3J4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyMDg4MTksImV4cCI6MjA5NDc4NDgxOX0.P4d2_5tNaoVG_u0tuotQX2aMX0xvxMPS-9UL1TKZwWA';

// 시설 ID 매핑
const FACILITY_IDS = {
    APARTMENT: '00000000-0000-0000-0000-000000000001', // 청주SK뷰자이 아파트
    FITNESS: '00000000-0000-0000-0000-000000000002'    // 청주SK뷰자이 필라테스
};

// Supabase 클라이언트 생성 함수
function createSharedSupabaseClient() {
    if (typeof supabase === 'undefined') {
        console.error('❌ Supabase library not loaded');
        return null;
    }
    return supabase.createClient(SHARED_SUPABASE_URL, SHARED_SUPABASE_ANON_KEY);
}

// 뒤로가기 버튼 추가 함수
function addBackToFacilitiesButton(containerId = 'backButtonContainer') {
    const container = document.getElementById(containerId);
    if (!container) {
        console.warn('Back button container not found');
        return;
    }
    
    const button = document.createElement('button');
    button.innerHTML = '<i class="fas fa-arrow-left"></i> 시설 선택으로 돌아가기';
    button.className = 'btn-back-facilities';
    button.onclick = () => {
        window.location.href = '../facilities.html';
    };
    
    container.appendChild(button);
}

// 현재 시설 타입 감지
function detectFacilityType() {
    const path = window.location.pathname;
    if (path.includes('/apartment/')) return 'apartment';
    if (path.includes('/fitness/')) return 'fitness';
    return null;
}

// 현재 시설 ID 가져오기
function getCurrentFacilityId() {
    const type = detectFacilityType();
    if (type === 'apartment') return FACILITY_IDS.APARTMENT;
    if (type === 'fitness') return FACILITY_IDS.FITNESS;
    return null;
}

console.log('✅ Shared config loaded');
