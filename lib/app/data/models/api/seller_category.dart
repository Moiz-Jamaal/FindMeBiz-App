class SellerCategory {
  final int? scbindid;
  final int? sellerid;
  final int? catid;
  final bool? active;

  SellerCategory({
    this.scbindid,
    this.sellerid,
    this.catid,
    this.active = true,
  });

  factory SellerCategory.fromJson(Map<String, dynamic> json) {
    return SellerCategory(
      scbindid: json['ScBindId'] as int?,
      sellerid: json['SellerId'] as int?,
      catid: json['CatId'] as int?,
      active: json['Active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scbindid != null) 'ScBindId': scbindid,
      'SellerId': sellerid,
      'CatId': catid,
      'Active': active,
    };
  }

  SellerCategory copyWith({
    int? scbindid,
    int? sellerid,
    int? catid,
    bool? active,
  }) {
    return SellerCategory(
      scbindid: scbindid ?? this.scbindid,
      sellerid: sellerid ?? this.sellerid,
      catid: catid ?? this.catid,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'SellerCategory(scbindid: $scbindid, sellerid: $sellerid, catid: $catid)';
  }
}
