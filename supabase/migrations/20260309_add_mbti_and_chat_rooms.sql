-- ========================================================
-- 1. user_profiles 테이블 생성 (MBTI 저장용)
-- ========================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mbti VARCHAR(4),
  mbti_updated_at TIMESTAMPTZ,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- 다른 사용자의 MBTI도 볼 수 있어야 같은 MBTI 방을 찾을 수 있음
CREATE POLICY "Users can read others mbti"
  ON user_profiles FOR SELECT
  USING (true);

-- ========================================================
-- 2. mbti_chat_rooms 테이블 (MBTI별 채팅방)
--    room_type: 'group' = 기질 그룹방 (NT/NF/SJ/SP)
--               'individual' = 개별 MBTI 방 (16개)
-- ========================================================
CREATE TABLE IF NOT EXISTS mbti_chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mbti VARCHAR(4) NOT NULL UNIQUE,
  room_type VARCHAR(16) NOT NULL DEFAULT 'individual',
  description TEXT DEFAULT '이 방은 가장 당신과 잘 어울리는 결이 맞는 사람들이 연결된 방입니다. 편하게 소통하세요',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE mbti_chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read chat rooms"
  ON mbti_chat_rooms FOR SELECT
  USING (true);

-- 4개 기질 그룹방 (메인 커뮤니티)
INSERT INTO mbti_chat_rooms (mbti, room_type, description) VALUES
  ('NT', 'group', '분석가형 — 이성적이고 전략적인 사고를 즐기는 사람들의 공간입니다. INTJ·INTP·ENTJ·ENTP가 함께합니다.'),
  ('NF', 'group', '외교관형 — 따뜻하고 이상적인 세계를 꿈꾸는 사람들의 공간입니다. INFJ·INFP·ENFJ·ENFP가 함께합니다.'),
  ('SJ', 'group', '관리자형 — 안정적이고 책임감 있게 세상을 지키는 사람들의 공간입니다. ISTJ·ISFJ·ESTJ·ESFJ가 함께합니다.'),
  ('SP', 'group', '탐험가형 — 자유롭고 순간을 즐기며 탐험하는 사람들의 공간입니다. ISTP·ISFP·ESTP·ESFP가 함께합니다.')
ON CONFLICT (mbti) DO NOTHING;

-- 16가지 개별 MBTI 채팅방
INSERT INTO mbti_chat_rooms (mbti, room_type) VALUES
  ('INTJ', 'individual'), ('INTP', 'individual'), ('ENTJ', 'individual'), ('ENTP', 'individual'),
  ('INFJ', 'individual'), ('INFP', 'individual'), ('ENFJ', 'individual'), ('ENFP', 'individual'),
  ('ISTJ', 'individual'), ('ISTP', 'individual'), ('ESTJ', 'individual'), ('ESTP', 'individual'),
  ('ISFJ', 'individual'), ('ISFP', 'individual'), ('ESFJ', 'individual'), ('ESFP', 'individual')
ON CONFLICT (mbti) DO NOTHING;

-- ========================================================
-- 3. mbti_chat_members 테이블 (방 참여자)
-- ========================================================
CREATE TABLE IF NOT EXISTS mbti_chat_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES mbti_chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(room_id, user_id)
);

ALTER TABLE mbti_chat_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read members"
  ON mbti_chat_members FOR SELECT
  USING (true);

CREATE POLICY "Users can join rooms"
  ON mbti_chat_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave rooms"
  ON mbti_chat_members FOR DELETE
  USING (auth.uid() = user_id);

-- ========================================================
-- 4. mbti_chat_messages 테이블 (채팅 메시지)
-- ========================================================
CREATE TABLE IF NOT EXISTS mbti_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES mbti_chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE mbti_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Room members can read messages"
  ON mbti_chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM mbti_chat_members
      WHERE mbti_chat_members.room_id = mbti_chat_messages.room_id
      AND mbti_chat_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Room members can send messages"
  ON mbti_chat_messages FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM mbti_chat_members
      WHERE mbti_chat_members.room_id = mbti_chat_messages.room_id
      AND mbti_chat_members.user_id = auth.uid()
    )
  );

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created
  ON mbti_chat_messages(room_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_members_room
  ON mbti_chat_members(room_id);

CREATE INDEX IF NOT EXISTS idx_chat_members_user
  ON mbti_chat_members(user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_mbti
  ON user_profiles(mbti);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id
  ON user_profiles(user_id);
