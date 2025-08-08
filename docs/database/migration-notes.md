# Migration and integration notes

## Mapping app models to DB

- User ⇄ user
- Seller extends User ⇄ seller + seller_category + seller_social_link
- Buyer extends User ⇄ buyer + buyer_favorite_seller + buyer_recent_seller
- Product ⇄ product + product_category + product_image
- Enquiry ⇄ enquiry + enquiry_category + enquiry_interested_seller
- EnquiryResponse ⇄ enquiry_response + enquiry_response_product + enquiry_response_attachment
- Seller Settings (module) ⇄ seller_settings
- Analytics (module) ⇄ analytics_event
- Order ⇄ order + order_item (CartItem maps into order_item with product_snapshot)

## IDs
- Generate ULIDs/UUIDs client-side or server-side; store as TEXT

## Timestamps
- created_at set on insert; updated_at set on update (use DB DEFAULTs or app responsibility)

## Minimal API contracts (examples)

- POST /sellers/{sellerId}/products
  - body: { name, description, price, categories[], images[], customAttributes }
  - creates product, product_category, product_image rows

- PATCH /sellers/{sellerId}/products/{productId}
  - upserts fields and categories/images (replace sets)

- POST /buyers/{buyerId}/enquiries
  - body: { title, description, categories[], images[], budgetMin, budgetMax, urgency, preferredLocation, additionalDetails }

- POST /enquiries/{enquiryId}/responses
  - body: { sellerId, message, productIds[], quotedPrice, availability, deliveryTime, attachments[], additionalInfo }

- PATCH /sellers/{sellerId}/settings
  - body: { businessOpen, acceptingOrders, businessHours, notifications, privacy, subscriptionPlan }

- POST /buyers/{buyerId}/orders
  - body: { sellerId, sellerName, items[{productId, quantity, notes}], deliveryAddress }
  - server computes unitPrice from product, totalAmount, persists order + order_items with product_snapshot

- GET /buyers/{buyerId}/orders?limit=20
- GET /sellers/{sellerId}/orders?limit=20

## Import/seed suggestions
- Seed categories as a flat list or taxonomy table if needed later
- No fixed category table is required now; store as strings with indexes

## Analytics
- Log view/click events minimally; add dimensions as needed in properties JSONB

## Future additions
- orders, payments, reviews/ratings, ad_campaign
- each can reference existing user/seller/product ids
