// 메인 페이지 콘솔에서 실행할 스크립트
(async function() {
    const apartments = [
        { name: 'e편한세상탕정퍼스트드림' },
        { name: '내포이지더원' },
        { name: '상도푸르지오클라베뉴' },
        { name: '파주디에트르에듀타운' },
        { name: '파주호반써밋웨스트파크' },
        { name: '헤링턴플레이스안성공도' },
        { name: '초월역힐스테이트' }
    ];

    console.log('🚀 아파트 추가 시작...');
    console.log('추가할 아파트:', apartments);

    try {
        // 메인 페이지의 supabase 클라이언트 사용
        if (typeof supabase === 'undefined') {
            console.error('❌ Supabase 클라이언트를 찾을 수 없습니다. 메인 페이지에서 실행해주세요.');
            return;
        }

        const { data, error } = await supabase
            .from('apartments')
            .insert(apartments)
            .select();

        if (error) {
            console.error('❌ 오류 발생:', error.message);
            console.error('상세 오류:', error);
        } else {
            console.log('✅ 성공! ' + data.length + '개 아파트가 추가되었습니다.');
            console.table(data);
            alert('✅ 성공! ' + data.length + '개 아파트가 추가되었습니다.');
        }
    } catch (err) {
        console.error('❌ 예외 발생:', err);
    }
})();
