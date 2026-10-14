-- Schema được khởi tạo tự động bởi app/server.js.
-- File này dùng để tham khảo khi cần tạo cấu trúc thủ công.
CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  location VARCHAR(160) NOT NULL,
  event_date TIMESTAMP NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS registrations (
  id SERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  attendee_name VARCHAR(120) NOT NULL,
  attendee_email VARCHAR(180) NOT NULL,
  ticket_code VARCHAR(30) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
