class CampaignDetails {
  final int campId;
  final String campGroup;
  final int sellerId;
  final String displayUrl;
  final String navigateUrl;
  final int credits;
  final String startDt;
  final String endDt;
  final String registerDt;
  final int? catId;
  final bool catRefOnly;
  final bool active;

  CampaignDetails({
    required this.campId,
    required this.campGroup,
    required this.sellerId,
    required this.displayUrl,
    required this.navigateUrl,
    required this.credits,
    required this.startDt,
    required this.endDt,
    required this.registerDt,
    this.catId,
    required this.catRefOnly,
    required this.active,
  });

  factory CampaignDetails.fromJson(Map<String, dynamic> json) {
    return CampaignDetails(
      campId: json['CampId'] as int,
      campGroup: json['CampGroup'] as String,
      sellerId: json['SellerId'] as int,
      displayUrl: json['DisplayUrl'] as String,
      navigateUrl: json['NavigateUrl'] as String,
      credits: json['Credits'] as int,
      startDt: json['StartDt'] as String,
      endDt: json['EndDt'] as String,
      registerDt: json['RegisterDt'] as String,
      catId: json['CatId'] as int?,
      catRefOnly: json['CatRefOnly'] as bool,
      active: json['Active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campId': campId,
      'campGroup': campGroup,
      'sellerId': sellerId,
      'displayUrl': displayUrl,
      'navigateUrl': navigateUrl,
      'credits': credits,
      'startDt': startDt,
      'endDt': endDt,
      'registerDt': registerDt,
      'catId': catId,
      'catRefOnly': catRefOnly,
      'active': active,
    };
  }
}
class CampaignResponse {
  final CampaignDetails campaign;
  final int remainingCredits;
  final int position;
  final int creditCost;
  final String? sellerName;
  final String? categoryName;

  CampaignResponse({
    required this.campaign,
    required this.remainingCredits,
    required this.position,
    required this.creditCost,
    this.sellerName,
    this.categoryName,
  });

  factory CampaignResponse.fromJson(Map<String, dynamic> json) {
    return CampaignResponse(
      campaign: CampaignDetails.fromJson(json['Campaign'] as Map<String, dynamic>),
      remainingCredits: json['RemainingCredits'] as int,
      position: json['Position'] as int,
      creditCost: json['CreditCost'] as int,
      sellerName: json['SellerName'] as String?,
      categoryName: json['CategoryName'] as String?,
    );
  }
}

class TopCampaignsRequest {
  final int? userId;
  final String campGroup;
  final int campaignCount;
  final List<int> userInterestCategories;

  TopCampaignsRequest({
    this.userId,
    required this.campGroup,
    required this.campaignCount,
    this.userInterestCategories = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'CampGroup': campGroup,
      'CampaignCount': campaignCount,
      'UserInterestCategories': userInterestCategories,
    };
  }
}

class TopCampaignsResponse {
  final bool success;
  final List<CampaignResponse> campaigns;
  final int totalFetched;
  final ViewRecord? viewRecord;

  TopCampaignsResponse({
    required this.success,
    required this.campaigns,
    required this.totalFetched,
    this.viewRecord,
  });

  factory TopCampaignsResponse.fromJson(Map<String, dynamic> json) {
    return TopCampaignsResponse(
      success: json['Success'] as bool,
      campaigns: (json['Campaigns'] as List<dynamic>)
          .map((item) => CampaignResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalFetched: json['TotalFetched'] as int,
      viewRecord: json['ViewRecord'] != null
          ? ViewRecord.fromJson(json['ViewRecord'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ViewRecord {
  final int userId;
  final String campGroup;
  final String campIdList;
  final String transDt;

  ViewRecord({
    required this.userId,
    required this.campGroup,
    required this.campIdList,
    required this.transDt,
  });

  factory ViewRecord.fromJson(Map<String, dynamic> json) {
    return ViewRecord(
      userId: json['UserId'] as int,
      campGroup: json['CampGroup'] as String,
      campIdList: json['CampIdList'] as String,
      transDt: json['TransDt'] as String,
    );
  }
}