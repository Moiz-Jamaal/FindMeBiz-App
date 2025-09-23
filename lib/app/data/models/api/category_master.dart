class CategoryMaster {
  final int? catid;
  final String catname;
  final int? parentcat;
  final bool? active;
  final String? icon; // full URL to SVG/PNG icon if provided by API

  CategoryMaster({
    this.catid,
    required this.catname,
    this.parentcat,
    this.active = true,
    this.icon,
  });

  factory CategoryMaster.fromJson(Map<String, dynamic> json) {
    // Be lenient with key casing and naming from different endpoints
    dynamic _firstNonNull(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return null;
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return CategoryMaster(
      catid: _toInt(_firstNonNull(['catId', 'CatId', 'catid'])),
      catname: (_firstNonNull(['catName', 'CatName', 'catname', 'Catname']) ?? '') as String,
      parentcat: _toInt(_firstNonNull(['parentCat', 'ParentCat', 'parentcat'])),
      active: (_firstNonNull(['active', 'Active']) as bool?) ?? true,
      icon: _firstNonNull(['icon', 'Icon', 'iconUrl', 'IconUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (catid != null) 'catid': catid,
      'catname': catname,
      'parentcat': parentcat,
      'active': active,
      if (icon != null) 'icon': icon,
    };
  }

  CategoryMaster copyWith({
    int? catid,
    String? catname,
    int? parentcat,
    bool? active,
    String? icon,
  }) {
    return CategoryMaster(
      catid: catid ?? this.catid,
      catname: catname ?? this.catname,
      parentcat: parentcat ?? this.parentcat,
      active: active ?? this.active,
      icon: icon ?? this.icon,
    );
  }

  @override
  String toString() {
    return 'CategoryMaster(catid: $catid, catname: $catname, parentcat: $parentcat, icon: $icon)';
  }
}
