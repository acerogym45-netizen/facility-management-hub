// Node.js로 아파트 추가
const fetch = require('node-fetch');

const SUPABASE_URL = 'https://ezyjulsdodriyxuaohmz.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV6eWp1bHNkb2RyaXl4dWFvaG16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU3MjE5NTYsImV4cCI6MjA1MTI5Nzk1Nn0.IzGLnExj7NeZFnGOGjzN7y0RFhPE4VWhxfb5fhqPR4k';

const apartments = [
    { name: 'e편한세상탕정퍼스트드림' },
    { name: '내포이지더원' },
    { name: '상도푸르지오클라베뉴' },
    { name: '파주디에트르에듀타운' },
    { name: '파주호반써밋웨스트파크' },
    { name: '헤링턴플레이스안성공도' },
    { name: '초월역힐스테이트' }
];

async function addApartments() {
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/apartments`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_KEY,
                'Authorization': `Bearer ${SUPABASE_KEY}`,
                'Prefer': 'return=representation'
            },
            body: JSON.stringify(apartments)
        });

        const data = await response.json();
        
        if (response.ok) {
            console.log('✅ 성공! 추가된 아파트:');
            data.forEach((apt, idx) => {
                console.log(`${idx + 1}. ${apt.name} (ID: ${apt.id})`);
            });
        } else {
            console.error('❌ 오류 발생:', data);
        }
    } catch (error) {
        console.error('❌ 네트워크 오류:', error);
    }
}

addApartments();
