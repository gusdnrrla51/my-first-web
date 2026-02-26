-- ============================================================
-- 1. diary_entries 테이블에 photo_url 컬럼 추가
-- ============================================================
ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- ============================================================
-- 2. diary-photos 스토리지 버킷 생성 (public, 2MB 제한)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'diary-photos',
  'diary-photos',
  true,
  2097152,  -- 2MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- ============================================================
-- 3. 스토리지 RLS 정책
-- ============================================================

-- 기존 정책 있으면 삭제 후 재생성 (멱등성 보장)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can upload own diary photos" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update own diary photos" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete own diary photos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can read diary photos" ON storage.objects;
END $$;

-- 업로드: 인증된 유저가 자기 user_id 폴더에만 업로드
CREATE POLICY "Users can upload own diary photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'diary-photos'
    AND (storage.foldername(name))[1] = 'diary_photos'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- 업데이트: 자기 파일만 upsert
CREATE POLICY "Users can update own diary photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'diary-photos'
    AND (storage.foldername(name))[1] = 'diary_photos'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- 삭제: 자기 파일만
CREATE POLICY "Users can delete own diary photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'diary-photos'
    AND (storage.foldername(name))[1] = 'diary_photos'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- 읽기: public 버킷이므로 누구나
CREATE POLICY "Anyone can read diary photos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'diary-photos');
