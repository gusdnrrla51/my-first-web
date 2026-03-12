-- raffle_rounds에 당첨자 연락처(전화번호) 컬럼 추가
ALTER TABLE raffle_rounds ADD COLUMN IF NOT EXISTS winner_contact TEXT;
