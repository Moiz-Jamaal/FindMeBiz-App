class SellerSettings {
  final int? sellerid;
  final bool? isopen;
  final String? notificationModes;
  final String? pushNotifications;
  final String? emailNotifications;
  final String? smsNotifications;
  final String? whatsappNotifications;
  final String? businessHours;
  final String? privacySettings;
  final String? otherSettings;
  final String? subscriptionPlan;
  final String? subscriptionDetails;
  final DateTime? updated;

  SellerSettings({
    this.sellerid,
    this.isopen = true,
    this.notificationModes,
    this.pushNotifications,
    this.emailNotifications,
    this.smsNotifications,
    this.whatsappNotifications,
    this.businessHours,
    this.privacySettings,
    this.otherSettings,
    this.subscriptionPlan,
    this.subscriptionDetails,
    this.updated,
  });

  factory SellerSettings.fromJson(Map<String, dynamic> json) {
    return SellerSettings(
      sellerid: json['SellerId'] as int?,
      isopen: json['IsOpen'] as bool? ?? true,
      notificationModes: json['NotificationModes'] as String?,
      pushNotifications: json['PushNotifications'] as String?,
      emailNotifications: json['EmailNotifications'] as String?,
      smsNotifications: json['SmsNotifications'] as String?,
      whatsappNotifications: json['WhatsappNotifications'] as String?,
      businessHours: json['BusinessHours'] as String?,
      privacySettings: json['PrivacySettings'] as String?,
      otherSettings: json['OtherSettings'] as String?,
      subscriptionPlan: json['SubscriptionPlan'] as String?,
      subscriptionDetails: json['SubscriptionDetails'] as String?,
      updated: json['Updated'] != null 
          ? DateTime.parse(json['Updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerid': sellerid,
      'isopen': isopen,
      'notification_modes': notificationModes,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'whatsapp_notifications': whatsappNotifications,
      'business_hours': businessHours,
      'privacy_settings': privacySettings,
      'other_settings': otherSettings,
      'subscription_plan': subscriptionPlan,
      'subscription_details': subscriptionDetails,
      'updated': updated?.toIso8601String(),
    };
  }

  SellerSettings copyWith({
    int? sellerid,
    bool? isopen,
    String? notificationModes,
    String? pushNotifications,
    String? emailNotifications,
    String? smsNotifications,
    String? whatsappNotifications,
    String? businessHours,
    String? privacySettings,
    String? otherSettings,
    String? subscriptionPlan,
    String? subscriptionDetails,
    DateTime? updated,
  }) {
    return SellerSettings(
      sellerid: sellerid ?? this.sellerid,
      isopen: isopen ?? this.isopen,
      notificationModes: notificationModes ?? this.notificationModes,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      whatsappNotifications: whatsappNotifications ?? this.whatsappNotifications,
      businessHours: businessHours ?? this.businessHours,
      privacySettings: privacySettings ?? this.privacySettings,
      otherSettings: otherSettings ?? this.otherSettings,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'SellerSettings(sellerid: $sellerid, isopen: $isopen, subscriptionPlan: $subscriptionPlan)';
  }
}
