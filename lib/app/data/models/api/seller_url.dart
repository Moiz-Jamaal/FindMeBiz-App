class SellerUrl {
  final int? urlid;
  final int? sellerid;
  final int? smid;
  final String? urllink;

  SellerUrl({
    this.urlid,
    this.sellerid,
    this.smid,
    this.urllink,
  });

  factory SellerUrl.fromJson(Map<String, dynamic> json) {
    return SellerUrl(
      urlid: json['UrlId'] as int?,
      sellerid: json['SellerId'] as int?,
      smid: json['SmId'] as int?,
      urllink: json['UrlLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (urlid != null) 'urlid': urlid,
      'sellerid': sellerid,
      'smid': smid,
      'urllink': urllink,
    };
  }

  SellerUrl copyWith({
    int? urlid,
    int? sellerid,
    int? smid,
    String? urllink,
  }) {
    return SellerUrl(
      urlid: urlid ?? this.urlid,
      sellerid: sellerid ?? this.sellerid,
      smid: smid ?? this.smid,
      urllink: urllink ?? this.urllink,
    );
  }

  @override
  String toString() {
    return 'SellerUrl(urlid: $urlid, sellerid: $sellerid, smid: $smid, urllink: $urllink)';
  }
}

class SocialMediaPlatform {
  final int? smid;
  final String sname;

  SocialMediaPlatform({
    this.smid,
    required this.sname,
  });

  factory SocialMediaPlatform.fromJson(Map<String, dynamic> json) {
    return SocialMediaPlatform(
      smid: json['smid'] as int?,
      sname: json['sname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (smid != null) 'smid': smid,
      'sname': sname,
    };
  }

  @override
  String toString() {
    return 'SocialMediaPlatform(smid: $smid, sname: $sname)';
  }
}
