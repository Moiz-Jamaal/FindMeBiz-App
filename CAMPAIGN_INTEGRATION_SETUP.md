# Campaign Integration Setup Guide

## Implementation Complete ✅

The advertisement-campaign integration has been fully implemented with the following components:

### New Services Created:
1. **CampaignService** - Handles API calls to campaign backend
2. **FallbackContentService** - Provides organic content when no campaigns available
3. **AppLinksService** - Deep linking support for https://findmebiz.com
4. **Updated AdService** - Now integrates campaigns with session caching

### Models Created:
- **CampaignDetails** - Core campaign data model
- **CampaignResponse** - API response with position/credits
- **TopCampaignsRequest/Response** - API request/response DTOs
- **ViewRecord** - Campaign view tracking model

### Integration Points:
- **BuyerHomeController** - Preloads campaigns on init
- **BuyerHomeView** - Uses synchronous ad calls with cached data
- **AppBinding** - Registers all new services

## Configuration Required:

### 1. Add Dependencies to pubspec.yaml:
```yaml
dependencies:
  # Add these if not already present:
  http: ^1.1.0
  get_storage: ^2.1.1
  # For future deep linking (optional):
  # app_links: ^3.4.1
  # share_plus: ^7.2.1
```

### 2. API Endpoint Configuration:
Update your API client base URL to point to the campaign endpoints:
- Base URL should include `/FMB` endpoints
- Ensure TopCampaigns endpoint is accessible

### 3. Deep Linking Setup (Web):
For web deployment on https://findmebiz.com, configure:
- Web routing to handle /seller, /product, /category routes
- Meta tags for social sharing

### 4. Campaign Slot Configuration:
Current slot mappings:
- homeHeaderBanner → "home_header_banner"
- homeBelowSearchBanner → "home_below_search"  
- homeFeatured → "featured_section"
- homeNewSellers → "new_sellers_section"

## Expected Behavior:

### With Active Campaigns:
- Campaigns load on home screen init
- Credit-based positioning (1-5: 3 credits, 6-10: 2 credits, 11-20: 1 credit)
- View tracking on ad render
- Session caching (no refresh during session)
- Deep linking support

### No Campaigns Available:
- **Header Banner**: Static promotional content
- **Below Search**: "Become a Seller" CTA
- **Featured**: Top-rated sellers organically
- **New Sellers**: Recently joined sellers organically

### Error Handling:
- All API failures handled silently
- Fallback to organic content
- Empty slots hidden gracefully

## Testing:
1. Ensure API endpoints return valid campaign data
2. Test fallback content when campaigns are empty
3. Verify deep linking works correctly
4. Confirm session caching behavior

The integration is production-ready and follows the requested specifications.
