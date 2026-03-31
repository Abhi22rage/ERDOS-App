class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String mobile;
  final String role;
  final String? category;
  final bool isVerified;
  final String? fcmToken;
  final String? address;
  final String? addressLine;
  final String? areaLocality;
  final String? city;
  final String? state;
  final String? district;
  final String? country;
  final int? postalCode;
  final DateTime? createdAt;
  final String? photoUrl;

  UserModel({
    required this.id,
    this.name,
    this.email,
    required this.mobile,
    required this.role,
    this.category,
    this.isVerified = false,
    this.fcmToken,
    this.address,
    this.addressLine,
    this.areaLocality,
    this.city,
    this.state,
    this.district,
    this.country,
    this.postalCode,
    this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      email: json['email'],
      mobile: json['phone'] ?? '',
      role: json['role'] ?? 'khalasi',
      category: json['category'],
      isVerified: json['is_verified'] ?? false,
      fcmToken: json['fcm_token'],
      address: json['address'],
      addressLine: json['address_line'],
      areaLocality: json['area_locality'],
      city: json['city'],
      state: json['state'],
      district: json['district'],
      country: json['country'],
      postalCode: json['postal_code'] is int ? json['postal_code'] : int.tryParse(json['postal_code']?.toString() ?? ''),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'role': role,
        'category': category,
        'is_verified': isVerified,
        'address': address,
        'address_line': addressLine,
        'area_locality': areaLocality,
        'city': city,
        'state': state,
        'district': district,
        'country': country,
        'postal_code': postalCode,
      };

  String get displayName => name ?? 'User';

  String get roleDisplay {
    const roleMap = {
      'khalasi': 'Khalasi',
      'jalmitra': 'Jalmitra',
      'je': 'Junior Engineer',
      'ae': 'Assistant Engineer',
      'aee': 'Asst. Executive Engineer',
      'ee': 'Executive Engineer',
      'se': 'Superintending Engineer',
      'addl_ce': 'Addl. Chief Engineer',
      'ce': 'Chief Engineer',
      'secretary': 'Secretary',
      'contractor': 'Contractor',
      'finance': 'Finance',
      'dc': 'DC',
      'admin': 'Admin',
    };
    return roleMap[role] ?? role.toUpperCase();
  }

  bool get canApprove => [
        'ee',
        'se',
        'addl_ce',
        'ce',
        'secretary',
        'admin',
      ].contains(role);

  bool get canReport => [
        'khalasi',
        'jalmitra',
        'je',
        'ae',
        'aee',
        'ee',
        'se',
        'admin',
      ].contains(role);

  String get initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }
}
