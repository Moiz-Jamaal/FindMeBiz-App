import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class AnalyticsController extends GetxController {
  // Time period selection
  final RxString selectedPeriod = 'Last 7 Days'.obs;
  final List<String> periodOptions = [
    'Today',
    'Yesterday', 
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
  ];
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  
  // Overview metrics
  final RxInt totalViews = 0.obs;
  final RxInt profileVisits = 0.obs;
  final RxInt productViews = 0.obs;
  final RxInt contactClicks = 0.obs;
  final RxInt directionsClicks = 0.obs;
  final RxInt favoriteAdds = 0.obs;
  
  // Performance trends
  final RxList<DailyMetric> viewsTrend = <DailyMetric>[].obs;
  final RxList<DailyMetric> contactsTrend = <DailyMetric>[].obs;
  
  // Product performance
  final RxList<ProductAnalytics> topProducts = <ProductAnalytics>[].obs;
  
  // Engagement metrics
  final RxDouble engagementRate = 0.0.obs;
  final RxDouble contactConversionRate = 0.0.obs;
  final RxInt averageSessionDuration = 0.obs; // in seconds
  
  // Traffic sources
  final RxList<TrafficSource> trafficSources = <TrafficSource>[].obs;
  
  // Customer insights
  final RxList<CustomerInsight> customerInsights = <CustomerInsight>[].obs;
  
  // Business hours analytics
  final RxList<HourlyMetric> hourlyTraffic = <HourlyMetric>[].obs;
  
  // Comparison metrics
  final RxDouble viewsGrowth = 0.0.obs;
  final RxDouble contactsGrowth = 0.0.obs;
  final RxDouble engagementGrowth = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    isLoading.value = true;
    
    // Simulate API call to load analytics data
    Future.delayed(const Duration(seconds: 2), () {
      _generateMockData();
      isLoading.value = false;
    });
  }

  void _generateMockData() {
    // Generate overview metrics based on selected period
    _generateOverviewMetrics();
    
    // Generate trends data
    _generateTrends();
    
    // Generate product performance
    _generateProductAnalytics();
    
    // Generate traffic sources
    _generateTrafficSources();
    
    // Generate customer insights
    _generateCustomerInsights();
    
    // Generate hourly traffic
    _generateHourlyTraffic();
    
    // Calculate growth metrics
    _calculateGrowthMetrics();
  }

  void _generateOverviewMetrics() {
    final multiplier = _getPeriodMultiplier();
    
    totalViews.value = (450 * multiplier).round();
    profileVisits.value = (89 * multiplier).round();
    productViews.value = (234 * multiplier).round();
    contactClicks.value = (23 * multiplier).round();
    directionsClicks.value = (15 * multiplier).round();
    favoriteAdds.value = (12 * multiplier).round();
    
    // Calculate derived metrics
    engagementRate.value = (contactClicks.value / totalViews.value * 100);
    contactConversionRate.value = (contactClicks.value / profileVisits.value * 100);
    averageSessionDuration.value = (45 + (multiplier * 10)).round();
  }

  void _generateTrends() {
    viewsTrend.clear();
    contactsTrend.clear();
    
    final days = _getPeriodDays();
    for (int i = days; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final baseViews = 50 + (i * 5) + (DateTime.now().millisecondsSinceEpoch % 30);
      final baseContacts = (baseViews * 0.15).round();
      
      viewsTrend.add(DailyMetric(
        date: date,
        value: baseViews.toDouble(),
      ));
      
      contactsTrend.add(DailyMetric(
        date: date,
        value: baseContacts.toDouble(),
      ));
    }
  }

  void _generateProductAnalytics() {
    topProducts.assignAll([
      ProductAnalytics(
        productName: 'Silk Sarees Collection',
        views: 156,
        clicks: 23,
        favorites: 8,
        conversionRate: 14.7,
      ),
      ProductAnalytics(
        productName: 'Handcrafted Jewelry',
        views: 132,
        clicks: 19,
        favorites: 6,
        conversionRate: 14.4,
      ),
      ProductAnalytics(
        productName: 'Traditional Wear',
        views: 98,
        clicks: 12,
        favorites: 4,
        conversionRate: 12.2,
      ),
      ProductAnalytics(
        productName: 'Wedding Collection',
        views: 87,
        clicks: 11,
        favorites: 5,
        conversionRate: 12.6,
      ),
      ProductAnalytics(
        productName: 'Accessories',
        views: 76,
        clicks: 8,
        favorites: 3,
        conversionRate: 10.5,
      ),
    ]);
  }

  void _generateTrafficSources() {
    trafficSources.assignAll([
      TrafficSource(
        source: 'Search',
        visits: 234,
        percentage: 45.2,
        color: Colors.blue,
        icon: Icons.search,
      ),
      TrafficSource(
        source: 'Map Discovery',
        visits: 156,
        percentage: 30.1,
        color: Colors.green,
        icon: Icons.map,
      ),
      TrafficSource(
        source: 'Featured Listing',
        visits: 89,
        percentage: 17.2,
        color: Colors.orange,
        icon: Icons.star,
      ),
      TrafficSource(
        source: 'Direct',
        visits: 39,
        percentage: 7.5,
        color: Colors.purple,
        icon: Icons.link,
      ),
    ]);
  }

  void _generateCustomerInsights() {
    customerInsights.assignAll([
      CustomerInsight(
        title: 'Peak Shopping Hours',
        description: 'Most customers visit between 2 PM - 6 PM',
        icon: Icons.schedule,
        color: Colors.blue,
        actionText: 'Optimize availability',
      ),
      CustomerInsight(
        title: 'Popular Categories',
        description: 'Silk sarees and jewelry are most viewed',
        icon: Icons.trending_up,
        color: Colors.green,
        actionText: 'Add more products',
      ),
      CustomerInsight(
        title: 'Customer Behavior',
        description: '68% of visitors check contact info',
        icon: Icons.people,
        color: Colors.orange,
        actionText: 'Update contact details',
      ),
      CustomerInsight(
        title: 'Repeat Visitors',
        description: '23% are returning customers',
        icon: Icons.refresh,
        color: Colors.purple,
        actionText: 'Build loyalty program',
      ),
    ]);
  }

  void _generateHourlyTraffic() {
    hourlyTraffic.clear();
    for (int hour = 0; hour < 24; hour++) {
      double traffic;
      
      // Simulate realistic traffic patterns
      if (hour < 6) {
        traffic = 2 + (hour * 0.5); // Low early morning
      } else if (hour < 10) {
        traffic = 5 + (hour * 2); // Morning increase
      } else if (hour < 14) {
        traffic = 20 + (hour * 3); // Midday peak
      } else if (hour < 18) {
        traffic = 45 + (hour * 2); // Afternoon peak
      } else if (hour < 22) {
        traffic = 35 - (hour - 18) * 5; // Evening decline
      } else {
        traffic = 8 - (hour - 22) * 2; // Night low
      }
      
      hourlyTraffic.add(HourlyMetric(
        hour: hour,
        traffic: traffic,
      ));
    }
  }

  void _calculateGrowthMetrics() {
    // Simulate growth calculations
    viewsGrowth.value = 12.5; // +12.5% vs previous period
    contactsGrowth.value = 8.3; // +8.3% vs previous period
    engagementGrowth.value = -2.1; // -2.1% vs previous period
  }

  double _getPeriodMultiplier() {
    switch (selectedPeriod.value) {
      case 'Today':
        return 0.2;
      case 'Yesterday':
        return 0.18;
      case 'Last 7 Days':
        return 1.0;
      case 'Last 30 Days':
        return 4.2;
      case 'This Month':
        return 3.8;
      case 'Last Month':
        return 4.0;
      default:
        return 1.0;
    }
  }

  int _getPeriodDays() {
    switch (selectedPeriod.value) {
      case 'Today':
      case 'Yesterday':
        return 1;
      case 'Last 7 Days':
        return 7;
      case 'Last 30 Days':
      case 'This Month':
      case 'Last Month':
        return 30;
      default:
        return 7;
    }
  }

  void updatePeriod(String period) {
    selectedPeriod.value = period;
    _loadAnalyticsData();
  }

  void refreshData() {
    isRefreshing.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      _generateMockData();
      isRefreshing.value = false;
      
      Get.snackbar(
        'Analytics Updated',
        'Latest data has been loaded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  String get engagementRateText {
    if (engagementRate.value >= 15) {
      return 'Excellent';
    } else if (engagementRate.value >= 10) {
      return 'Good';
    } else if (engagementRate.value >= 5) {
      return 'Average';
    } else {
      return 'Needs Improvement';
    }
  }

  Color get engagementRateColor {
    if (engagementRate.value >= 15) {
      return Colors.green;
    } else if (engagementRate.value >= 10) {
      return Colors.blue;
    } else if (engagementRate.value >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String get performanceSummary {
    final views = totalViews.value;
    final contacts = contactClicks.value;
    
    if (views > 500 && contacts > 30) {
      return 'Outstanding performance! Your business is attracting high traffic and engagement.';
    } else if (views > 200 && contacts > 15) {
      return 'Good performance! Consider promoting your best products to increase engagement.';
    } else if (views > 100 && contacts > 5) {
      return 'Moderate performance. Try updating your profile and adding more products.';
    } else {
      return 'Getting started! Focus on completing your profile and adding quality product photos.';
    }
  }

  List<String> get recommendations {
    final recommendations = <String>[];
    
    if (engagementRate.value < 10) {
      recommendations.add('Improve product photos and descriptions to increase engagement');
    }
    
    if (contactConversionRate.value < 15) {
      recommendations.add('Make your contact information more prominent');
    }
    
    if (productViews.value > profileVisits.value * 2) {
      recommendations.add('Add more product variety to keep visitors engaged');
    }
    
    if (favoriteAdds.value < contactClicks.value * 0.5) {
      recommendations.add('Encourage customers to save your profile as favorite');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Great job! Keep maintaining your high-quality profile and products.');
    }
    
    return recommendations;
  }
}

// Data models for analytics
class DailyMetric {
  final DateTime date;
  final double value;

  DailyMetric({
    required this.date,
    required this.value,
  });
}

class ProductAnalytics {
  final String productName;
  final int views;
  final int clicks;
  final int favorites;
  final double conversionRate;

  ProductAnalytics({
    required this.productName,
    required this.views,
    required this.clicks,
    required this.favorites,
    required this.conversionRate,
  });
}

class TrafficSource {
  final String source;
  final int visits;
  final double percentage;
  final Color color;
  final IconData icon;

  TrafficSource({
    required this.source,
    required this.visits,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class CustomerInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String actionText;

  CustomerInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.actionText,
  });
}

class HourlyMetric {
  final int hour;
  final double traffic;

  HourlyMetric({
    required this.hour,
    required this.traffic,
  });
}