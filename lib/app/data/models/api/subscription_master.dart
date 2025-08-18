class SubscriptionMaster {
  final int? subid;
  final String subname;
  final String subconfig;
  final bool? active;

  SubscriptionMaster({
    this.subid,
    required this.subname,
    required this.subconfig,
    this.active = true,
  });

  factory SubscriptionMaster.fromJson(Map<String, dynamic> json) {
    return SubscriptionMaster(
      subid: json['SubId'] as int?,
      subname: json['SubName'] as String,
      subconfig: json['SubConfig'] as String,
      active: json['Active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (subid != null) 'subid': subid,
      'subname': subname,
      'subconfig': subconfig,
      'active': active,
    };
  }

  SubscriptionMaster copyWith({
    int? subid,
    String? subname,
    String? subconfig,
    bool? active,
  }) {
    return SubscriptionMaster(
      subid: subid ?? this.subid,
      subname: subname ?? this.subname,
      subconfig: subconfig ?? this.subconfig,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'SubscriptionMaster(subid: $subid, subname: $subname, active: $active)';
  }
}
