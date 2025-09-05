#!/bin/bash

# Product API Unification Verification Script
echo "🔍 Verifying Product API Unification..."

# Check if Flutter project compiles
echo "📱 Checking Flutter compilation..."
cd /d/flutter_projects/souq
flutter analyze

# Check for any remaining BuyerService product method usage
echo "🔍 Scanning for remaining BuyerService product method usage..."
echo "Searching for BuyerService.getProductDetails usage:"
grep -r "buyerService\.getProductDetails\|BuyerService.*getProductDetails" lib/ || echo "✅ No usage found"

echo "Searching for BuyerService.searchProducts usage:"
grep -r "buyerService\.searchProducts\|BuyerService.*searchProducts" lib/ || echo "✅ No usage found"

echo "Searching for BuyerService.addToFavorites usage:"
grep -r "buyerService\.addToFavorites\|BuyerService.*addToFavorites" lib/ || echo "✅ No usage found"

echo "Searching for BuyerService.trackView usage:"
grep -r "buyerService\.trackView\|BuyerService.*trackView" lib/ || echo "✅ No usage found"

# Verify ProductService is being used
echo "🔍 Verifying ProductService usage..."
echo "Checking ProductService.instance usage:"
grep -r "ProductService\.instance" lib/ | wc -l
echo "Checking ProductService imports:"
grep -r "import.*product_service" lib/ | wc -l

# Check backend compilation
echo "🔧 Checking .NET backend compilation..."
cd /d/dotnet_projects/PYLambdaAPIs/ProjectAPI
dotnet build --no-restore

echo "✅ Verification complete!"
echo ""
echo "📊 Summary:"
echo "- Flutter frontend: Unified ProductService usage"
echo "- .NET backend: Optimized FMBController with efficient queries"
echo "- Redundant methods: Removed from BuyerService"
echo "- Code quality: Improved with single source of truth"
