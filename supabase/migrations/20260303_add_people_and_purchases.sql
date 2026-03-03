-- ============================================================
-- diary_entries 테이블에 people, purchases 컬럼 추가
-- ============================================================
ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS people JSONB DEFAULT '[]';

ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS purchases JSONB DEFAULT '[]';
