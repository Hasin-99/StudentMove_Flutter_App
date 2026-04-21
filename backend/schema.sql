-- StudentMove — core tables for Laravel admin + mobile API.
-- Charset utf8mb4 for Bangla text in names/tags.

CREATE TABLE routes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(191) NOT NULL COMMENT 'e.g. Uttara — DSC',
  code VARCHAR(64) NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL
);

CREATE TABLE buses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL COMMENT 'e.g. SM-101',
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL
);

-- weekday: 0=Sat .. 5=Thu (matches Flutter tabs)
CREATE TABLE schedules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  route_id BIGINT UNSIGNED NOT NULL,
  bus_id BIGINT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL CHECK (weekday BETWEEN 0 AND 5),
  time_label VARCHAR(32) NOT NULL COMMENT '7.00 AM',
  date_label VARCHAR(32) NOT NULL COMMENT '12 May',
  origin VARCHAR(191) NOT NULL,
  university_tags JSON NULL COMMENT '["DSC","DU"]',
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  CONSTRAINT fk_sched_route FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
  CONSTRAINT fk_sched_bus FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE RESTRICT,
  INDEX idx_route_day (route_id, weekday)
);
