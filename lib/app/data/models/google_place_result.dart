class GooglePlaceResult {
  final String id; // Places API 'name' (resource name)
  final String displayName;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;

  GooglePlaceResult({
    required this.id,
    required this.displayName,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.photoUrl,
  });

  Uri get mapsUri {
    if (latitude != null && longitude != null) {
      return Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}');
    }
    final q = displayName.isNotEmpty
        ? Uri.encodeComponent(displayName)
        : Uri.encodeComponent(formattedAddress);
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  }
}
