-- Add unique constraint to userstats table
ALTER TABLE userstats
ADD CONSTRAINT unique_userstats_user UNIQUE (user_id);