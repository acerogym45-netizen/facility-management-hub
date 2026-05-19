// Test script to fetch Google Sheets and examine structure
const sheetId = '1Xr3AdjGVXdSFhF7WfT9h6NrZNvHVCIDy25RVWemCfN8';
const sheetName = '월간 민원 처리 현황 DB';
const url = `https://docs.google.com/spreadsheets/d/${sheetId}/gviz/tq?tqx=out:json&sheet=${encodeURIComponent(sheetName)}`;

fetch(url)
  .then(res => res.text())
  .then(text => {
    const jsonText = text.substring(47, text.length - 2);
    const data = JSON.parse(jsonText);
    
    console.log('=== FULL DATA STRUCTURE ===');
    console.log(JSON.stringify(data, null, 2));
    
    console.log('\n=== ROWS ===');
    console.log('Total rows:', data.table.rows.length);
    
    console.log('\n=== FIRST ROW (HEADER) ===');
    if (data.table.rows[0]) {
      console.log('Row object keys:', Object.keys(data.table.rows[0]));
      console.log('c array:', data.table.rows[0].c);
    }
    
    console.log('\n=== SECOND ROW (FIRST DATA) ===');
    if (data.table.rows[1]) {
      console.log('Row object:', data.table.rows[1]);
      const cells = data.table.rows[1].c || [];
      console.log('\n=== CELL STRUCTURE ===');
      cells.forEach((cell, idx) => {
        if (cell) {
          console.log(`Cell ${idx}:`, JSON.stringify(cell, null, 2));
        } else {
          console.log(`Cell ${idx}: null`);
        }
      });
    }
  })
  .catch(err => console.error('Error:', err));
