class UsersProfile {
  final int? userid;
  final String? googleid;
  final String username;
  final String? fullname;
  final String emailid;
  final String? upassword;
  final String? dob;
  final String? sex;
  final String? mobileno;
  final String? whatsappno;
  final bool? active;
  final DateTime? createddt;
  final DateTime? updateddt;

  UsersProfile({
    this.userid,
    this.googleid,
    required this.username,
    this.fullname,
    required this.emailid,
    this.upassword,
    this.dob,
    this.sex,
    this.mobileno,
    this.whatsappno,
    this.active = true,
    this.createddt,
    this.updateddt,
  });

  factory UsersProfile.fromJson(Map<String, dynamic> json) {
    // Accept both PascalCase (API typed models) and lowercase (raw SELECT) keys
    T? pick<T>(String a, String b) {
      final v = json[a];
      if (v != null) return v as T;
      final v2 = json[b];
      return v2 == null ? null : v2 as T;
    }
    return UsersProfile(
      userid: pick<int>('UserId', 'userid'),
      googleid: pick<String>('GoogleId', 'googleid'),
      username: (pick<String>('Username', 'username'))!,
      fullname: pick<String>('FullName', 'fullname'),
      emailid: (pick<String>('EmailId', 'emailid'))!,
      upassword: pick<String>('UPassword', 'upassword'),
      dob: pick<String>('Dob', 'dob'),
      sex: pick<String>('Sex', 'sex'),
      mobileno: pick<String>('MobileNo', 'mobileno'),
      whatsappno: pick<String>('WhatsappNo', 'whatsappno'),
      active: (pick<bool>('Active', 'active')) ?? true,
      createddt: (json['CreatedDt'] ?? json['createddt']) != null 
          ? DateTime.parse(((json['CreatedDt'] ?? json['createddt']) as String))
          : null,
      updateddt: (json['UpdatedDt'] ?? json['updateddt']) != null 
          ? DateTime.parse(((json['UpdatedDt'] ?? json['updateddt']) as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userid != null) 'UserId': userid,
      if (googleid != null) 'GoogleId': googleid,
      'Username': username,
      'FullName': fullname,
      'EmailId': emailid,
      if (upassword != null) 'UPassword': upassword,
      'Dob': dob,
      'Sex': sex,
      'MobileNo': mobileno,
      'WhatsappNo': whatsappno,
      'Active': active,
      'CreatedDt': createddt?.toIso8601String(),
      'UpdatedDt': updateddt?.toIso8601String(),
    };
  }

  UsersProfile copyWith({
    int? userid,
    String? googleid,
    String? username,
    String? fullname,
    String? emailid,
    String? upassword,
    String? dob,
    String? sex,
    String? mobileno,
    String? whatsappno,
    bool? active,
    DateTime? createddt,
    DateTime? updateddt,
  }) {
    return UsersProfile(
      userid: userid ?? this.userid,
      googleid: googleid ?? this.googleid,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      emailid: emailid ?? this.emailid,
      upassword: upassword ?? this.upassword,
      dob: dob ?? this.dob,
      sex: sex ?? this.sex,
      mobileno: mobileno ?? this.mobileno,
      whatsappno: whatsappno ?? this.whatsappno,
      active: active ?? this.active,
      createddt: createddt ?? this.createddt,
      updateddt: updateddt ?? this.updateddt,
    );
  }

  @override
  String toString() {
    return 'UsersProfile(userid: $userid, username: $username, emailid: $emailid)';
  }
}
