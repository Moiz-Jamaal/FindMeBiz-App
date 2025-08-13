# FindMeBiz Database Architecture

This document proposes a complete backend data model for FindMeBiz, aligned with current Flutter models and seller/buyer flows. It includes:
- Entity-Relationship (ER) design
- SQL (PostgreSQL) schema with indexes and constraints
- Firestore (NoSQL) alternative structure
- Seed/ID conventions and audit columns
- Notes on analytics, search, and future extensions

Use either SQL or Firestore depending on your backend stack. The entity names mirror the app models.

## Core principles
- Stable IDs as strings (ULIDs or UUIDv7)
- created_at/updated_at on all records
- Soft-delete via `is_active` when practical
- Keep arrays in SQL via junction tables
- Denormalize safe counters (e.g., response_count) with triggers

---

## ER Model (high level)

Users (User)
- Seller (extends User)
- Buyer (extends User)

Seller 1 — N Product
Buyer 1 — N Enquiry
Enquiry 1 — N EnquiryResponse (by Sellers)
Seller N — N Enquiry (interest) via enquiry_interest
Product N — N Category via product_category
Seller N — N Category via seller_category
Buyer N — N Seller (favorites) via buyer_favorite_seller
Buyer N — N Seller (recently_viewed) via buyer_recent_seller

Plus:
- Media (images/attachments) linked to products and enquiry_responses
- Settings for Seller
- Analytics events (append-only)
 - Orders (buyer checkout) with order_items

---

## PostgreSQL schema

### Conventions
- snake_case table and column names
- TEXT for ids (uuid/ulid)
- timestamptz for time
- JSONB for flexible maps

### Tables

1) user
- id TEXT PK
- email TEXT UNIQUE NOT NULL
- full_name TEXT NOT NULL
- role TEXT CHECK (role IN ('seller','buyer')) NOT NULL
- profile_image TEXT NULL
- phone_number TEXT NULL
- created_at timestamptz NOT NULL
- updated_at timestamptz NOT NULL
- is_active BOOLEAN NOT NULL DEFAULT TRUE

2) seller
- user_id TEXT PK FK -> user(id) ON DELETE CASCADE
- business_name TEXT NOT NULL
- bio TEXT NULL
- business_logo TEXT NULL
- whatsapp_number TEXT NULL
- stall_latitude DOUBLE PRECISION NULL
- stall_longitude DOUBLE PRECISION NULL
- stall_address TEXT NULL
- stall_number TEXT NULL
- stall_area TEXT NULL
- is_profile_published BOOLEAN NOT NULL DEFAULT FALSE
- published_at timestamptz NULL
- profile_completion_score DOUBLE PRECISION NOT NULL DEFAULT 0

3) seller_category
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- category TEXT NOT NULL
PK (seller_id, category)

4) seller_social_link
- id TEXT PK
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- url TEXT NOT NULL
- created_at timestamptz NOT NULL

5) buyer
- user_id TEXT PK FK -> user(id) ON DELETE CASCADE
- address TEXT NULL
- preferred_language TEXT NOT NULL DEFAULT 'English'
- preferences JSONB NOT NULL DEFAULT '{}'
- last_login_at timestamptz NULL

6) buyer_favorite_seller
- buyer_id TEXT FK -> buyer(user_id) ON DELETE CASCADE
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- created_at timestamptz NOT NULL
PK (buyer_id, seller_id)

7) buyer_recent_seller
- buyer_id TEXT FK -> buyer(user_id) ON DELETE CASCADE
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- viewed_at timestamptz NOT NULL
- UNIQUE (buyer_id, seller_id)

8) product
- id TEXT PK
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- name TEXT NOT NULL
- description TEXT NOT NULL
- price NUMERIC(12,2) NULL
- is_available BOOLEAN NOT NULL DEFAULT TRUE
- custom_attributes JSONB NOT NULL DEFAULT '{}'
- created_at timestamptz NOT NULL
- updated_at timestamptz NOT NULL

9) product_category
- product_id TEXT FK -> product(id) ON DELETE CASCADE
- category TEXT NOT NULL
PK (product_id, category)

10) product_image
- id TEXT PK
- product_id TEXT FK -> product(id) ON DELETE CASCADE
- url TEXT NOT NULL
- position INT NOT NULL DEFAULT 0
- created_at timestamptz NOT NULL

11) enquiry
- id TEXT PK
- buyer_id TEXT FK -> buyer(user_id) ON DELETE CASCADE
- title TEXT NOT NULL
- description TEXT NOT NULL
- budget_min NUMERIC(12,2) NULL
- budget_max NUMERIC(12,2) NULL
- urgency TEXT NOT NULL DEFAULT 'medium' CHECK (urgency IN ('low','medium','high','urgent'))
- preferred_location TEXT NULL
- additional_details JSONB NOT NULL DEFAULT '{}'
- is_active BOOLEAN NOT NULL DEFAULT TRUE
- response_count INT NOT NULL DEFAULT 0
- created_at timestamptz NOT NULL
- updated_at timestamptz NOT NULL

12) enquiry_category
- enquiry_id TEXT FK -> enquiry(id) ON DELETE CASCADE
- category TEXT NOT NULL
PK (enquiry_id, category)

13) enquiry_interested_seller
- enquiry_id TEXT FK -> enquiry(id) ON DELETE CASCADE
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- created_at timestamptz NOT NULL
PK (enquiry_id, seller_id)

14) enquiry_response
- id TEXT PK
- enquiry_id TEXT FK -> enquiry(id) ON DELETE CASCADE
- seller_id TEXT FK -> seller(user_id) ON DELETE CASCADE
- message TEXT NOT NULL
- quoted_price NUMERIC(12,2) NULL
- availability TEXT NULL CHECK (availability IN ('available','limited','custom_order'))
- delivery_time TEXT NULL
- additional_info JSONB NOT NULL DEFAULT '{}'
- is_read BOOLEAN NOT NULL DEFAULT FALSE
- status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','negotiating'))
- created_at timestamptz NOT NULL
- updated_at timestamptz NOT NULL

15) enquiry_response_product
- response_id TEXT FK -> enquiry_response(id) ON DELETE CASCADE
- product_id TEXT FK -> product(id) ON DELETE CASCADE
PK (response_id, product_id)

16) enquiry_response_attachment
- id TEXT PK
- response_id TEXT FK -> enquiry_response(id) ON DELETE CASCADE
- url TEXT NOT NULL
- created_at timestamptz NOT NULL

17) seller_settings
- seller_id TEXT PK FK -> seller(user_id) ON DELETE CASCADE
- business_open BOOLEAN NOT NULL DEFAULT TRUE
- accepting_orders BOOLEAN NOT NULL DEFAULT TRUE
- business_hours JSONB NOT NULL DEFAULT '{}'   -- per-day hours
- notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE
- push_notifications BOOLEAN NOT NULL DEFAULT TRUE
- email_notifications BOOLEAN NOT NULL DEFAULT TRUE
- sms_notifications BOOLEAN NOT NULL DEFAULT FALSE
- privacy_settings JSONB NOT NULL DEFAULT '{}' -- visibility options
- subscription_plan TEXT NOT NULL DEFAULT 'Free'
- updated_at timestamptz NOT NULL

18) analytics_event
- id TEXT PK
- actor_user_id TEXT FK -> user(id) ON DELETE SET NULL
- seller_id TEXT NULL FK -> seller(user_id) ON DELETE SET NULL
- product_id TEXT NULL FK -> product(id) ON DELETE SET NULL
- enquiry_id TEXT NULL FK -> enquiry(id) ON DELETE SET NULL
- type TEXT NOT NULL  -- e.g., 'product_view','enquiry_created','response_sent'
- properties JSONB NOT NULL DEFAULT '{}'
- occurred_at timestamptz NOT NULL

19) order (optional now)
- See DDL for `order` and `order_item` tables aligned with `Order` model

### Indexing suggestions
- user(email)
- product(seller_id), product(name text_pattern_ops)
- enquiry(buyer_id, created_at DESC)
- enquiry_response(enquiry_id, created_at DESC)
- analytics_event(type, occurred_at DESC)
- GIN indexes on JSONB fields accessed by filters (custom_attributes, properties)

### Triggers (optional but recommended)
- After insert/delete on enquiry_response: update enquiry.response_count


## Firestore alternative (collections)

- users/{userId}
  - role: 'seller'|'buyer'
  - ...common fields
- sellers/{sellerId}
  - business profile
  - categories: [string]
  - social_links: [string]
  - settings: { businessOpen, acceptingOrders, businessHours, notifications: {...}, privacy: {...}, subscriptionPlan }
- buyers/{buyerId}
  - favorites: [sellerId]
  - recentlyViewed: [sellerId]
  - preferences: { ... }
- products/{productId}
  - sellerId
  - categories: [string]
  - images: [url]
  - customAttributes: {}
- enquiries/{enquiryId}
  - buyerId
  - categories: [string]
  - interestedSellerIds: [sellerId]
  - responseCount
- enquiryResponses/{responseId}
  - enquiryId, sellerId
  - productIds: [productId]
  - attachments: [url]
- analyticsEvents/{eventId}
- orders/{orderId} with embedded items (or subcollection items)

Notes:
- Subcollections can also be used: enquiries/{enquiryId}/responses, products/{productId}/images
- Keep counters (responseCount) with Cloud Functions

---

## ID and timestamp strategy
- Prefer ULIDs for sortable ids
- Set created_at on insert; updated_at on each update (DB default or app-side)

## File storage
- Store images/attachments in object storage (S3/GCS/Cloud Storage). Persist only URLs in DB.

## Security and privacy
- Authorization checks must ensure:
  - Sellers can only mutate their own products, responses, settings
  - Buyers can only mutate their own enquiries and preferences

## Future-ready tables (not created yet)
- payment, review, rating, subscription, notification
- ad_campaign, ad_insight (ties to Seller Advertising module when backend available)

---

## SQL DDL

See `postgresql.sql` for runnable SQL.
