import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_links_service.dart';

/// Service to handle URL opening - either in Chrome or via app links
class UrlHandlerService extends GetxService {
  AppLinksService? _appLinksService;
  
  AppLinksService get appLinksService {
    _appLinksService ??= Get.find<AppLinksService>();
    return _appLinksService!;
  }

  /// Handle campaign URL - app link or external browser
  Future<void> handleCampaignUrl(String url, {Map<String, dynamic>? payload}) async {
    try {
      // Check if it's a findmebiz.com URL for deep linking
      if (url.startsWith('https://findmebiz.com')) {
        final handled = await appLinksService.handleAppLink(url);
        if (!handled) {
          // If app linking fails, open in browser
          await _openInBrowser(url);
        }
      } else {
        // External URL - open in Chrome/browser
        await _openInBrowser(url);
      }
    } catch (e) {
      print('Failed to handle campaign URL: $e');
    }
  }

  /// Open URL in external browser (Chrome)
  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Generate deep link URLs for campaigns
  String generateSellerCampaignUrl(int sellerId, String? sellerName) {
    return appLinksService.generateSellerLink(sellerId, sellerName: sellerName);
  }

  String generateProductCampaignUrl(int productId, String? productName) {
    return appLinksService.generateProductLink(productId, productName: productName);
  }
}
