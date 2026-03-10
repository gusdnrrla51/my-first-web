-- ========================================================
-- 🎟️ 응모(래플) 시스템 테이블
-- ========================================================

-- 1. user_profiles에 ticket_count 추가
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS ticket_count INTEGER DEFAULT 0;

-- 2. raffle_entries — 사용자 응모 내역
CREATE TABLE IF NOT EXISTS raffle_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  number INTEGER NOT NULL CHECK (number >= 1 AND number <= 10000),
  week_key TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_raffle_entries_user ON raffle_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_raffle_entries_week ON raffle_entries(week_key);

ALTER TABLE raffle_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own entries" ON raffle_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own entries" ON raffle_entries FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. raffle_rounds — 주차별 추첨 라운드
CREATE TABLE IF NOT EXISTS raffle_rounds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_key TEXT NOT NULL UNIQUE,
  winning_number INTEGER CHECK (winning_number >= 1 AND winning_number <= 10000),
  winner_user_id UUID REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'drawn')),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE raffle_rounds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read rounds" ON raffle_rounds FOR SELECT USING (true);
CREATE POLICY "Authenticated can insert rounds" ON raffle_rounds FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated can update rounds" ON raffle_rounds FOR UPDATE USING (auth.uid() IS NOT NULL);

-- 4. raffle_claims — 당첨자 정보 제출 (관리자 확인용)
CREATE TABLE IF NOT EXISTS raffle_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_key TEXT NOT NULL,
  name TEXT NOT NULL,
  contact TEXT NOT NULL,
  claimed_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE raffle_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own claims" ON raffle_claims FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own claims" ON raffle_claims FOR INSERT WITH CHECK (auth.uid() = user_id);
