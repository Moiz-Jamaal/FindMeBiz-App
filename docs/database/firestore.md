# Firestore data model

This mirrors the app models and keeps write paths simple. Use Cloud Functions for counters and denormalization.

## Collections

users/{userId}
- email, fullName, role, profileImage, phoneNumber
- createdAt, updatedAt, isActive

sellers/{sellerId}
- businessName, bio, businessLogo, whatsappNumber
- categories: [string]
- socialLinks: [string]
- stallLocation: { latitude, longitude, address, stallNumber, area }
- isProfilePublished, publishedAt, profileCompletionScore
- settings: {
  businessOpen, acceptingOrders,
  businessHours: { mon: [{open:'09:00', close:'17:00'}], ... },
  notifications: { enabled, push, email, sms },
  privacy: { showPhone: true, ... },
  subscriptionPlan: 'Free',
  updatedAt
}

buyers/{buyerId}
- address, preferredLanguage, preferences, lastLoginAt
- favoriteSellerIds: [sellerId]
- recentlyViewedSellerIds: [sellerId]

products/{productId}
- sellerId, name, description, price, isAvailable
- categories: [string]
- images: [url]
- customAttributes: {}
- createdAt, updatedAt

enquiries/{enquiryId}
- buyerId, title, description
- categories: [string]
- images: [url]
- budgetMin, budgetMax, urgency, preferredLocation
- additionalDetails: {}
- isActive, responseCount
- interestedSellerIds: [sellerId]
- createdAt, updatedAt

enquiryResponses/{responseId}
- enquiryId, sellerId
- message, productIds: [productId]
- quotedPrice, availability, deliveryTime
- attachments: [url]
- additionalInfo: {}
- isRead, status
- createdAt, updatedAt

analyticsEvents/{eventId}
- actorUserId, sellerId, productId, enquiryId
- type, properties, occurredAt

orders/{orderId}
- buyerId, sellerId, sellerName
- totalAmount, status, orderDate, deliveryDate
- deliveryAddress, trackingNumber, notes
- items: [
  {
    id, productId, quantity, unitPrice, addedAt, notes,
    productSnapshot: { name, price, images, customAttributes, ... }
  }
]

## Notes
- Use security rules to scope writes by role and ownership
- For subcollections alternative:
  - enquiries/{enquiryId}/responses/{responseId}
  - products/{productId}/images/{imageId}
  - orders/{orderId}/items/{itemId}
- Keep read models (e.g., a seller feed) in separate aggregated collections if needed
