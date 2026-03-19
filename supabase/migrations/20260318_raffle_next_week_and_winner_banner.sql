-- ========================================================
-- 응모 시스템 개선: 다음 주 응모 + 당첨자 배너
-- ========================================================

-- 1. user_profiles에 email 컬럼 추가 (당첨자 표시용)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. raffle_rounds에 당첨자 이메일(마스킹) 컬럼 추가
ALTER TABLE raffle_rounds ADD COLUMN IF NOT EXISTS winner_email_masked TEXT;
