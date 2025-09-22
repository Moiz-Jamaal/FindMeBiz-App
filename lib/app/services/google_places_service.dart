import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:souq/app/core/constants/app_constants.dart';
import 'package:souq/app/data/models/google_place_result.dart';

class GooglePlacesService {
  GooglePlacesService._();
  static final GooglePlacesService instance = GooglePlacesService._();

  Future<List<GooglePlaceResult>> nearbyBusinesses({
    required double latitude,
    required double longitude,
    String? keyword,
    int radiusMeters = 2000,
    int pageSize = 8,
  }) async {
    final apiKey = AppConstants.googlePlacesApiKey;
    if (apiKey.isEmpty) return [];

    // Using "searchText" with a location bias to approximate nearby business search
    final body = <String, dynamic>{
      'textQuery': (keyword != null && keyword.trim().isNotEmpty)
          ? keyword
          : 'business',
      'pageSize': pageSize,
      'languageCode': 'en',
      if (AppConstants.googlePlacesCountryBias.isNotEmpty)
        'regionCode': AppConstants.googlePlacesCountryBias.toUpperCase(),
      'locationBias': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radiusMeters,
        }
      }
    };

    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'places.name,places.displayName,places.formattedAddress,places.location,places.photos.name,places.photos.widthPx,places.photos.heightPx',
    };

    try {
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final List places = (data['places'] as List?) ?? const [];
  return places.map<GooglePlaceResult>((p) {
        final loc = p['location'] as Map<String, dynamic>?;
        final lat = loc != null ? (loc['latitude'] as num?)?.toDouble() : null;
        final lng = loc != null ? (loc['longitude'] as num?)?.toDouble() : null;
        final displayName = (p['displayName']?['text']?.toString() ?? '').trim();
        // Build a photo URL if available (Places v1 Photos API)
        String? photoUrl;
        final photos = p['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          final token = (photos.first as Map<String, dynamic>)['name']?.toString();
          if (token != null && token.isNotEmpty) {
            // token is a resource name like "places/XXXX/photos/YYYY"; must remain in path (do not URL-encode slashes)
            photoUrl = 'https://places.googleapis.com/v1/$token/media?key=$apiKey&maxWidthPx=640';
          }
        }
        return GooglePlaceResult(
          id: p['name']?.toString() ?? '',
          displayName: displayName.isNotEmpty
              ? displayName
              : (p['formattedAddress']?.toString() ?? ''),
          formattedAddress: p['formattedAddress']?.toString() ?? '',
          latitude: lat,
          longitude: lng,
          photoUrl: photoUrl,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
