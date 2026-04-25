-- KAWACH Production Tables Migration
-- Run this in your Supabase SQL Editor

-- Live location tracking for guardian dashboard
CREATE TABLE IF NOT EXISTS sos_live_location (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  battery_pct INTEGER DEFAULT 100,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE sos_live_location ENABLE ROW LEVEL SECURITY;

-- Users can upsert their own location
CREATE POLICY "Users can upsert own location" ON sos_live_location
  FOR ALL USING (auth.uid() = user_id);

-- Guardians can read location of users they guard
CREATE POLICY "Guardians can read tracked user location" ON sos_live_location
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM guardians 
      WHERE guardians.user_id = sos_live_location.user_id
    )
  );

-- Ensure sos_alerts has all required columns
ALTER TABLE sos_alerts ADD COLUMN IF NOT EXISTS origin TEXT DEFAULT 'online';
ALTER TABLE sos_alerts ADD COLUMN IF NOT EXISTS cancel_reason TEXT;
ALTER TABLE sos_alerts ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Index for fast live location lookups
CREATE INDEX IF NOT EXISTS idx_sos_live_location_user ON sos_live_location(user_id);
