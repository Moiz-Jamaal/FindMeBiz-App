class AppConstants {
  // Private constructor
  AppConstants._();
  
  // App Info
  static const String appName = 'FindMeBiz';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Seller & Buyer Connect Platform';
  
  // API Base URLs (Placeholder)
  static const String baseUrl = 'https://api.findmebiz.com';
  static const String apiVersion = '/v1';
  
  // Storage Keys
  static const String userToken = 'user_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
  static const String isFirstTime = 'is_first_time';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  
  static const double cardElevation = 2.0;
  static const double modalElevation = 8.0;
  
  // Image Constraints
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerProduct = 5;
  static const double imageQuality = 0.8;
  
  // Text Limits
  static const int maxBioLength = 300;
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 500;
  static const int maxBusinessNameLength = 80;
  
  // Map Configuration
  static const double defaultLatitude = 21.1702; // Surat coordinates
  static const double defaultLongitude = 72.8311;
  static const double defaultZoom = 15.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 10.0;
  
  // Pagination
  static const int itemsPerPage = 20;
  static const int initialPage = 1;
  
  // Pricing
  static const double sellerEntryFee = 500.0; // INR
  static const String currency = '₹';
  static const String currencyCode = 'INR';
  
  // Contact Info
  static const String supportEmail = 'support@findmebiz.com';
  static const String supportPhone = '+91-9876543210';
  static const String whatsappNumber = '+919876543210';
  
  // Social Media
  static const String instagramHandle = '@findmebiz';
  static const String facebookPage = 'findmebiz';
  
  // Categories (will be dynamic later)
  static const List<String> productCategories = [
    'Apparel',
    'Jewelry',
    'Food & Beverages',
    'Art & Crafts',
    'Home Decor',
    'Electronics',
    'Books & Stationery',
    'Beauty & Personal Care',
    'Others',
  ];
  
  // File Extensions
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.webp'
  ];
  
  // Google Places API
  // Provide your key at build time using:
  // flutter run --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY
  static const String googlePlacesApiKey = 'AIzaSyARkcflc7555oG33PkeveARH6mDENlpDFM';
  // Optional: country bias for autocomplete (ISO 3166-1 alpha-2), e.g., 'in' for India
  static const String googlePlacesCountryBias = 'in';
  // City bias: Surat, Gujarat, India (used for Places Autocomplete bias)
  static const double googlePlacesBiasLatitude = 21.1702; // Surat
  static const double googlePlacesBiasLongitude = 72.8311; // Surat
  // Optional: search radius (in meters) for location biasing when coordinates are available
  static const int googlePlacesBiasRadiusMeters = 50000; // 50km
  // Web CORS proxy (optional). Example: 'https://cors.isomorphic-git.org/'
  static const String webCorsProxyUrl = '';
  
  // Validation Patterns
  static const String emailPattern = 
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$';
  static const String urlPattern = 
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
}

class AppStrings {
  // Private constructor
  AppStrings._();
  
  // General
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String tryAgain = 'Try Again';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String submit = 'Submit';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String done = 'Done';
  static const String skip = 'Skip';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  
  // Welcome & Onboarding
  static const String welcome = 'Welcome to FindMeBiz';
  static const String welcomeSubtitle = 'Connect, Discover, Trade at the biggest Istefada event';
  static const String chooseRole = 'What brings you here?';
  static const String seller = 'I\'m a Seller';
  static const String buyer = 'I\'m a Buyer';
  static const String sellerDescription = 'Showcase my products and connect with buyers';
  static const String buyerDescription = 'Discover amazing products and connect with sellers';
  
  // Authentication
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String businessName = 'Business Name';
  
  // Navigation
  static const String home = 'Home';
  static const String search = 'Search';
  static const String map = 'Map';
  static const String profile = 'Profile';
  static const String dashboard = 'Dashboard';
  static const String products = 'Products';
  static const String analytics = 'Analytics';
  
  // Seller Features
  static const String createProfile = 'Create Your Profile';
  static const String addProduct = 'Add Product';
  static const String myProducts = 'My Products';
  static const String stallLocation = 'Stall Location';
  static const String publishProfile = 'Publish Profile';
  static const String profilePreview = 'Profile Preview';
  
  // Buyer Features
  static const String featuredSellers = 'Featured Sellers';
  static const String newSellers = 'New Sellers';
  static const String browseCategories = 'Browse Categories';
  static const String nearbyStalls = 'Nearby Stalls';
  static const String contactSeller = 'Contact Seller';
  
  // Errors
  static const String emailRequired = 'Email is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String nameRequired = 'Name is required';
  static const String businessNameRequired = 'Business name is required';
  
  // Success Messages
  static const String profileCreated = 'Profile created successfully!';
  static const String productAdded = 'Product added successfully!';
  static const String profilePublished = 'Profile published successfully!';
  static const String paymentSuccessful = 'Payment completed successfully!';
}
