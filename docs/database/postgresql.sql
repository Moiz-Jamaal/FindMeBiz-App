-- FindMeBiz PostgreSQL schema
-- Run in a fresh database. Adjust extensions/roles as needed.

CREATE TABLE "user" (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('seller','buyer')),
  profile_image TEXT NULL,
  phone_number TEXT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE seller (
  user_id TEXT PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  bio TEXT NULL,
  business_logo TEXT NULL,
  whatsapp_number TEXT NULL,
  stall_latitude DOUBLE PRECISION NULL,
  stall_longitude DOUBLE PRECISION NULL,
  stall_address TEXT NULL,
  stall_number TEXT NULL,
  stall_area TEXT NULL,
  is_profile_published BOOLEAN NOT NULL DEFAULT FALSE,
  published_at timestamptz NULL,
  profile_completion_score DOUBLE PRECISION NOT NULL DEFAULT 0
);

CREATE TABLE seller_category (
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  PRIMARY KEY (seller_id, category)
);

CREATE TABLE seller_social_link (
  id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE buyer (
  user_id TEXT PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
  address TEXT NULL,
  preferred_language TEXT NOT NULL DEFAULT 'English',
  preferences JSONB NOT NULL DEFAULT '{}',
  last_login_at timestamptz NULL
);

CREATE TABLE buyer_favorite_seller (
  buyer_id TEXT NOT NULL REFERENCES buyer(user_id) ON DELETE CASCADE,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (buyer_id, seller_id)
);

CREATE TABLE buyer_recent_seller (
  buyer_id TEXT NOT NULL REFERENCES buyer(user_id) ON DELETE CASCADE,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  viewed_at timestamptz NOT NULL,
  UNIQUE (buyer_id, seller_id)
);

CREATE TABLE product (
  id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(12,2) NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  custom_attributes JSONB NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE product_category (
  product_id TEXT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  PRIMARY KEY (product_id, category)
);

CREATE TABLE product_image (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL
);

CREATE TABLE enquiry (
  id TEXT PRIMARY KEY,
  buyer_id TEXT NOT NULL REFERENCES buyer(user_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  budget_min NUMERIC(12,2) NULL,
  budget_max NUMERIC(12,2) NULL,
  urgency TEXT NOT NULL DEFAULT 'medium' CHECK (urgency IN ('low','medium','high','urgent')),
  preferred_location TEXT NULL,
  additional_details JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  response_count INT NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE enquiry_category (
  enquiry_id TEXT NOT NULL REFERENCES enquiry(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  PRIMARY KEY (enquiry_id, category)
);

CREATE TABLE enquiry_interested_seller (
  enquiry_id TEXT NOT NULL REFERENCES enquiry(id) ON DELETE CASCADE,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (enquiry_id, seller_id)
);

CREATE TABLE enquiry_response (
  id TEXT PRIMARY KEY,
  enquiry_id TEXT NOT NULL REFERENCES enquiry(id) ON DELETE CASCADE,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  quoted_price NUMERIC(12,2) NULL,
  availability TEXT NULL CHECK (availability IN ('available','limited','custom_order')),
  delivery_time TEXT NULL,
  additional_info JSONB NOT NULL DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','negotiating')),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE enquiry_response_product (
  response_id TEXT NOT NULL REFERENCES enquiry_response(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  PRIMARY KEY (response_id, product_id)
);

CREATE TABLE enquiry_response_attachment (
  id TEXT PRIMARY KEY,
  response_id TEXT NOT NULL REFERENCES enquiry_response(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE seller_settings (
  seller_id TEXT PRIMARY KEY REFERENCES seller(user_id) ON DELETE CASCADE,
  business_open BOOLEAN NOT NULL DEFAULT TRUE,
  accepting_orders BOOLEAN NOT NULL DEFAULT TRUE,
  business_hours JSONB NOT NULL DEFAULT '{}',
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  sms_notifications BOOLEAN NOT NULL DEFAULT FALSE,
  privacy_settings JSONB NOT NULL DEFAULT '{}',
  subscription_plan TEXT NOT NULL DEFAULT 'Free',
  updated_at timestamptz NOT NULL
);

CREATE TABLE analytics_event (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT NULL REFERENCES "user"(id) ON DELETE SET NULL,
  seller_id TEXT NULL REFERENCES seller(user_id) ON DELETE SET NULL,
  product_id TEXT NULL REFERENCES product(id) ON DELETE SET NULL,
  enquiry_id TEXT NULL REFERENCES enquiry(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  properties JSONB NOT NULL DEFAULT '{}',
  occurred_at timestamptz NOT NULL
);

-- Orders (optional: enable when buyer checkout is live)
CREATE TABLE "order" (
  id TEXT PRIMARY KEY,
  buyer_id TEXT NOT NULL REFERENCES buyer(user_id) ON DELETE RESTRICT,
  seller_id TEXT NOT NULL REFERENCES seller(user_id) ON DELETE RESTRICT,
  seller_name TEXT NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending','confirmed','processing','shipped','delivered','cancelled')),
  order_date timestamptz NOT NULL,
  delivery_date timestamptz NULL,
  delivery_address TEXT NOT NULL,
  tracking_number TEXT NULL,
  notes TEXT NULL
);

CREATE TABLE order_item (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES "order"(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES product(id) ON DELETE RESTRICT,
  product_snapshot JSONB NOT NULL, -- denormalized product at purchase time
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12,2) NOT NULL,
  line_total NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  added_at timestamptz NOT NULL,
  notes TEXT NULL
);

-- Indexes
CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_product_seller ON product(seller_id);
CREATE INDEX idx_product_name_pattern ON product(name text_pattern_ops);
CREATE INDEX idx_enquiry_buyer_created ON enquiry(buyer_id, created_at DESC);
CREATE INDEX idx_response_enquiry_created ON enquiry_response(enquiry_id, created_at DESC);
CREATE INDEX idx_event_type_time ON analytics_event(type, occurred_at DESC);

-- Optional: JSONB GIN indexes
CREATE INDEX idx_product_custom_attributes_gin ON product USING GIN (custom_attributes);
CREATE INDEX idx_event_properties_gin ON analytics_event USING GIN (properties);

-- Orders indexes
CREATE INDEX idx_order_buyer_date ON "order"(buyer_id, order_date DESC);
CREATE INDEX idx_order_seller_date ON "order"(seller_id, order_date DESC);

-- Trigger to maintain enquiry.response_count
CREATE OR REPLACE FUNCTION trg_update_enquiry_response_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE enquiry SET response_count = response_count + 1, updated_at = NOW() WHERE id = NEW.enquiry_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE enquiry SET response_count = response_count - 1, updated_at = NOW() WHERE id = OLD.enquiry_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enquiry_response_count
AFTER INSERT OR DELETE ON enquiry_response
FOR EACH ROW EXECUTE FUNCTION trg_update_enquiry_response_count();
