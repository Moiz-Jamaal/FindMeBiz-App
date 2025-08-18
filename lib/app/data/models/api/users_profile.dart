class UsersProfile {
  final int? userid;
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
    return UsersProfile(
      userid: json['UserId'] as int?,
      username: json['Username'] as String,
      fullname: json['FullName'] as String?,
      emailid: json['EmailId'] as String,
      upassword: json['UPassword'] as String?,
      dob: json['Dob'] as String?,
      sex: json['Sex'] as String?,
      mobileno: json['MobileNo'] as String?,
      whatsappno: json['WhatsappNo'] as String?,
      active: json['Active'] as bool? ?? true,
      createddt: json['CreatedDt'] != null 
          ? DateTime.parse(json['CreatedDt'] as String)
          : null,
      updateddt: json['UpdatedDt'] != null 
          ? DateTime.parse(json['UpdatedDt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userid != null) 'userid': userid,
      'username': username,
      'fullname': fullname,
      'emailid': emailid,
      if (upassword != null) 'upassword': upassword,
      'dob': dob,
      'sex': sex,
      'mobileno': mobileno,
      'whatsappno': whatsappno,
      'active': active,
      'createddt': createddt?.toIso8601String(),
      'updateddt': updateddt?.toIso8601String(),
    };
  }

  UsersProfile copyWith({
    int? userid,
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
