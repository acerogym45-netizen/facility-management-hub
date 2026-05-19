const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://qgpqhtuynxhmgawakjxe.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFncHFodHV5bnhobWdhd2FranhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyOTQyNTEsImV4cCI6MjA4Mjg3MDI1MX0.WNljQIKDbeZCDlXe8fpBdZs58XRFfujGt7lBGfq_pVg';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function fetchApartments() {
    try {
        const { data, error } = await supabase
            .from('apartments')
            .select('id, name, google_sheet_id, google_sheet_name')
            .order('name');
        
        if (error) throw error;
        
        console.log('\n===== 아파트별 구글 시트 정보 =====\n');
        console.log(`총 ${data.length}개 아파트\n`);
        
        data.forEach((apt, index) => {
            console.log(`${index + 1}. ${apt.name}`);
            console.log(`   - 구글 시트 ID: ${apt.google_sheet_id || '❌ 없음'}`);
            console.log(`   - 시트 탭 이름: ${apt.google_sheet_name || '❌ 없음'}`);
            console.log(`   - 상태: ${apt.google_sheet_id ? '✅ 설정됨' : '⚠️ 미설정'}\n`);
        });
        
        // JSON으로도 출력
        console.log('\n===== JSON 데이터 =====');
        console.log(JSON.stringify(data, null, 2));
        
    } catch (error) {
        console.error('Error:', error.message);
    }
}

fetchApartments();
