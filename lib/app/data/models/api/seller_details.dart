class SellerDetails {
  final int? sellerid;
  final int? userid;
  final String? businessname;
  final String? profilename;
  final String? bio;
  final String? logo;
  final String? contactno;
  final String? mobileno;
  final String? whatsappno;
  final String? address;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;
  final String? geolocation;
  final int? establishedyear;
  final bool? ispublished;
  final DateTime? publishedat;

  SellerDetails({
    this.sellerid,
    this.userid,
    this.businessname,
    this.profilename,
    this.bio,
    this.logo,
    this.contactno,
    this.mobileno,
    this.whatsappno,
    this.address,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.geolocation,
    this.establishedyear,
    this.ispublished = false,
    this.publishedat,
  });

  // Getter for backward compatibility
  int? get sellerId => sellerid;

  factory SellerDetails.fromJson(Map<String, dynamic> json) {
    return SellerDetails(
      sellerid: json['SellerId'] as int?,
      userid: json['UserId'] as int?,
      businessname: json['BusinessName'] as String?,
      profilename: json['ProfileName'] as String?,
      bio: json['Bio'] as String?,
      logo: json['Logo'] as String?,
      contactno: json['ContactNo'] as String?,
      mobileno: json['MobileNo'] as String?,
      whatsappno: json['WhatsappNo'] as String?,
      address: json['Address'] as String?,
      area: json['Area'] as String?,
      city: json['City'] as String?,
      state: json['State'] as String?,
      pincode: json['Pincode'] as String?,
      geolocation: json['GeoLocation'] as String?,
      establishedyear: json['EstablishedYear'] as int?,
      ispublished: json['IsPublished'] as bool? ?? false,
      publishedat: json['PublishedAt'] != null 
          ? DateTime.parse(json['PublishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sellerid != null) 'sellerid': sellerid,
      'userid': userid,
      'businessname': businessname,
      'profilename': profilename,
      'bio': bio,
      'logo': logo,
      'contactno': contactno,
      'mobileno': mobileno,
      'whatsappno': whatsappno,
      'address': address,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'geolocation': geolocation,
      'establishedyear': establishedyear,
      'ispublished': ispublished,
      'publishedat': publishedat?.toIso8601String(),
    };
  }

  SellerDetails copyWith({
    int? sellerid,
    int? userid,
    String? businessname,
    String? profilename,
    String? bio,
    String? logo,
    String? contactno,
    String? mobileno,
    String? whatsappno,
    String? address,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? geolocation,
    int? establishedyear,
    bool? ispublished,
    DateTime? publishedat,
  }) {
    return SellerDetails(
      sellerid: sellerid ?? this.sellerid,
      userid: userid ?? this.userid,
      businessname: businessname ?? this.businessname,
      profilename: profilename ?? this.profilename,
      bio: bio ?? this.bio,
      logo: logo ?? this.logo,
      contactno: contactno ?? this.contactno,
      mobileno: mobileno ?? this.mobileno,
      whatsappno: whatsappno ?? this.whatsappno,
      address: address ?? this.address,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      geolocation: geolocation ?? this.geolocation,
      establishedyear: establishedyear ?? this.establishedyear,
      ispublished: ispublished ?? this.ispublished,
      publishedat: publishedat ?? this.publishedat,
    );
  }

  @override
  String toString() {
    return 'SellerDetails(sellerid: $sellerid, businessname: $businessname, city: $city)';
  }
}

class SellerDetailsExtended extends SellerDetails {
  final List<dynamic>? categories;
  final List<dynamic>? settings;
  final List<dynamic>? urls;

  SellerDetailsExtended({
    super.sellerid,
    super.userid,
    super.businessname,
    super.profilename,
    super.bio,
    super.logo,
    super.contactno,
    super.mobileno,
    super.whatsappno,
    super.address,
    super.area,
    super.city,
    super.state,
    super.pincode,
    super.geolocation,
    super.establishedyear,
    super.ispublished = null,
    super.publishedat,
    this.categories,
    this.settings,
    this.urls,
  });

  factory SellerDetailsExtended.fromJson(Map<String, dynamic> json) {
    final base = SellerDetails.fromJson(json);
    return SellerDetailsExtended(
      sellerid: base.sellerid,
      userid: base.userid,
      businessname: base.businessname,
      profilename: base.profilename,
      bio: base.bio,
      logo: base.logo,
      contactno: base.contactno,
      mobileno: base.mobileno,
      whatsappno: base.whatsappno,
      address: base.address,
      area: base.area,
      city: base.city,
      state: base.state,
      pincode: base.pincode,
      geolocation: base.geolocation,
      establishedyear: base.establishedyear,
      ispublished: base.ispublished,
      publishedat: base.publishedat,
      categories: json['categories'] as List<dynamic>?,
      settings: json['settings'] as List<dynamic>?,
      urls: json['urls'] as List<dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'categories': categories,
      'settings': settings,
      'urls': urls,
    });
    return json;
  }
}
