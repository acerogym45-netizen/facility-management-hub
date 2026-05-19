// 구글 시트에 추가할 Apps Script
// 1. 구글 시트 열기
// 2. 확장 프로그램 → Apps Script
// 3. 아래 코드 붙여넣기
// 4. 배포 → 새 배포 → 웹 앱 → 배포
// 5. 웹 앱 URL 복사

function doPost(e) {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('월간 민원 처리 현황 DB');
    const data = JSON.parse(e.postData.contents);
    
    // 데이터 추가
    sheet.appendRow([
      data.date,
      data.area,
      data.category,
      data.resident,
      data.contact,
      data.content,
      data.status,
      data.action,
      data.handler,
      data.completedDate,
      data.note
    ]);
    
    return ContentService.createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({ success: false, error: error.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput('Apps Script is running');
}
