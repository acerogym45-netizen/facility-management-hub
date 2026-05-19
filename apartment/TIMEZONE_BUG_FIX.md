# 특이사항 표시 버그 수정 완료

**커밋**: 38ced29  
**날짜**: 2026-05-07

---

## 문제

특이사항 입력했는데 관리자 페이지에서 안 보임

## 원인

**시간대 변환 버그**:
- `scan_time`은 UTC 저장
- `note_date/note_time`은 KST 저장
- 코드가 UTC에 9시간을 **또** 더해서 매칭 실패

예시:
```
출근: 2026-05-08 12:35 (KST)
DB: scan_time = 2026-05-08T03:35:00Z (UTC)
    note_time = 12:35:00 (KST)

잘못된 코드:
  UTC에 9시간 더함 → 12:35 (UTC) = 21:35 (KST)
  note_time 12:35와 비교 → 9시간 차이 → 매칭 실패!

올바른 코드:
  timeZone: 'Asia/Seoul' 사용 → 12:35 (KST)
  note_time 12:35와 비교 → 0분 차이 → 매칭 성공!
```

## 해결

**수정 전**:
```javascript
const kstDate = new Date(scanDate.getTime() + (9 * 60 * 60 * 1000));
const timeStr = kstDate.toISOString().split('T')[1].substring(0, 5);
```

**수정 후**:
```javascript
const timeStr = scanDate.toLocaleTimeString('ko-KR', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
  timeZone: 'Asia/Seoul'
});
```

## 결과

✅ 특이사항이 정확히 표시됨!

테스트:
1. scan.html에서 공휴일/근무시간외/비근무일/중복 출근 → 사유 입력
2. 관리자 페이지 상세 조회 탭 → 특이사항 컬럼에 뱃지 + 사유 표시
3. 콘솔에서 "✅ 매칭 성공" 로그 확인

배포: https://bdxi-qr-attendance.vercel.app/
