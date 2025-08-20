class CategoryMaster {
  final int? catid;
  final String catname;
  final int? parentcat;
  final bool? active;

  CategoryMaster({
    this.catid,
    required this.catname,
    this.parentcat,
    this.active = true,
  });

  factory CategoryMaster.fromJson(Map<String, dynamic> json) {
    return CategoryMaster(
      catid: json['catId'] ?? json['CatId'] as int?,
      catname: json['catName'] ?? json['CatName'] as String,
      parentcat: json['parentCat'] ?? json['ParentCat'] as int?,
      active: json['active'] ?? json['Active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (catid != null) 'catid': catid,
      'catname': catname,
      'parentcat': parentcat,
      'active': active,
    };
  }

  CategoryMaster copyWith({
    int? catid,
    String? catname,
    int? parentcat,
    bool? active,
  }) {
    return CategoryMaster(
      catid: catid ?? this.catid,
      catname: catname ?? this.catname,
      parentcat: parentcat ?? this.parentcat,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'CategoryMaster(catid: $catid, catname: $catname, parentcat: $parentcat)';
  }
}
