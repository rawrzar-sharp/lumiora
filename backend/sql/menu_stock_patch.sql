-- Optional patch if your deployed DB still lacks the stock column
ALTER TABLE menu
  ADD COLUMN IF NOT EXISTS stock INT NOT NULL DEFAULT 0;
