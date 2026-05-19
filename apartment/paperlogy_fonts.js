// Paperlogy 폰트 Base64 데이터
const PAPERLOGY_FONTS = {
  regular: null,
  bold: null
};

// 폰트 데이터 로드 함수
async function loadPaperlogyFonts() {
  try {
    const [regularResponse, boldResponse] = await Promise.all([
      fetch('paperlogy_regular_base64.txt'),
      fetch('paperlogy_bold_base64.txt')
    ]);
    
    PAPERLOGY_FONTS.regular = await regularResponse.text();
    PAPERLOGY_FONTS.bold = await boldResponse.text();
    
    console.log('✅ Paperlogy 폰트 로드 완료');
    return true;
  } catch (error) {
    console.error('❌ Paperlogy 폰트 로드 실패:', error);
    return false;
  }
}

// PDF에 폰트 추가하는 함수
function addPaperlogyFontsToPDF(pdf) {
  if (!PAPERLOGY_FONTS.regular || !PAPERLOGY_FONTS.bold) {
    console.warn('⚠️ Paperlogy 폰트가 로드되지 않았습니다');
    return false;
  }
  
  try {
    // Regular 폰트 추가
    pdf.addFileToVFS('Paperlogy-Regular.ttf', PAPERLOGY_FONTS.regular);
    pdf.addFont('Paperlogy-Regular.ttf', 'Paperlogy', 'normal');
    
    // Bold 폰트 추가
    pdf.addFileToVFS('Paperlogy-Bold.ttf', PAPERLOGY_FONTS.bold);
    pdf.addFont('Paperlogy-Bold.ttf', 'Paperlogy', 'bold');
    
    console.log('✅ PDF에 Paperlogy 폰트 추가 완료');
    return true;
  } catch (error) {
    console.error('❌ PDF 폰트 추가 실패:', error);
    return false;
  }
}
