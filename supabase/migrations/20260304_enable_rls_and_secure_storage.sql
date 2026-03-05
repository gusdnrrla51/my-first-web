-- ============================================================
-- 1. diary_entries 테이블 RLS 활성화 + 정책 설정
--    → 각 유저는 자기 일기만 CRUD 가능
-- ============================================================

-- RLS 활성화
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

-- 기존 정책 있으면 삭제 (멱등성)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can read own diary entries" ON diary_entries;
  DROP POLICY IF EXISTS "Users can insert own diary entries" ON diary_entries;
  DROP POLICY IF EXISTS "Users can update own diary entries" ON diary_entries;
  DROP POLICY IF EXISTS "Users can delete own diary entries" ON diary_entries;
END $$;

-- SELECT: 본인 일기만 조회
CREATE POLICY "Users can read own diary entries"
  ON diary_entries FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- INSERT: 본인 user_id로만 삽입
CREATE POLICY "Users can insert own diary entries"
  ON diary_entries FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- UPDATE: 본인 일기만 수정
CREATE POLICY "Users can update own diary entries"
  ON diary_entries FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: 본인 일기만 삭제
CREATE POLICY "Users can delete own diary entries"
  ON diary_entries FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- 2. 사진 스토리지: public 읽기 → 본인만 읽기로 변경
--    → 사진 URL을 알아도 인증 없이 접근 불가
-- ============================================================

-- 기존 public 읽기 정책 삭제
DROP POLICY IF EXISTS "Anyone can read diary photos" ON storage.objects;

-- 본인 사진만 읽기 가능
CREATE POLICY "Users can read own diary photos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'diary-photos'
    AND (storage.foldername(name))[1] = 'diary_photos'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- 버킷을 private으로 전환
UPDATE storage.buckets
  SET public = false
  WHERE id = 'diary-photos';
