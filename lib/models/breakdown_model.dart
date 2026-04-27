class BreakdownModel {
  final String id;
  final String? reportNumber;
  final String title;
  final String? description;
  final String status;
  final String severity;
  final String? assetType;
  final String? assetName;
  final String? assetId;
  final String? componentCategory;
  final String? componentType;
  final String? componentUnit;
  final double? locationLat;
  final double? locationLng;
  final String? locationAddress;
  final String? reportedBy;
  final String? reporterName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<WorkStageModel> workStages;
  final List<ApprovalModel> approvals;
  final List<String> mediaUrls;
  final List<RepairMediaModel> repairMedia;

  BreakdownModel({
    required this.id,
    this.reportNumber,
    required this.title,
    this.description,
    required this.status,
    required this.severity,
    this.assetType,
    this.assetName,
    this.assetId,
    this.componentCategory,
    this.componentType,
    this.componentUnit,
    this.locationLat,
    this.locationLng,
    this.locationAddress,
    this.reportedBy,
    this.reporterName,
    required this.createdAt,
    this.updatedAt,
    this.workStages = const [],
    this.approvals = const [],
    this.mediaUrls = const [],
    this.repairMedia = const [],
  });

  factory BreakdownModel.fromJson(Map<String, dynamic> json) {
    return BreakdownModel(
      id: json['id']?.toString() ?? '',
      reportNumber: json['report_number'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'reported',
      severity: json['severity'] ?? 'medium',
      assetType: json['asset_type'],
      assetName: json['asset']?['name'] ?? json['asset_name'],
      assetId: json['asset_id']?.toString(),
      componentCategory: json['component_category'],
      componentType: json['component_type'],
      componentUnit: json['component_unit'],
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      locationAddress: json['location_address'],
      reportedBy: json['reported_by']?.toString(),
      reporterName: json['reporter']?['name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      workStages: ((json['work_stages'] ?? json['workStages']) as List<dynamic>?)
              ?.map((s) => WorkStageModel.fromJson(s))
              .toList() ??
          [],
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((a) => ApprovalModel.fromJson(a))
              .toList() ??
          [],
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      repairMedia: (json['repair_media'] as List<dynamic>?)
              ?.map((m) => RepairMediaModel.fromJson(m))
              .toList() ??
          [],
    );
  }

  String get displayId =>
      reportNumber ?? 'INC-${id.length > 8 ? id.substring(0, 8) : id}';

  String get normalizedStatus {
    if (status == 'auto_approved' || status == 'approved') {
      return 'approved';
    }
    if (status == 'contractor_assigned') {
      return 'assigned';
    }
    if (status == 'certified') {
      return 'closed';
    }
    return status;
  }

  static const List<String> statusOrder = [
    'reported',
    'pending_approval',
    'approved',
    'assigned',
    'in_progress',
    'completed',
    'closed',
  ];

  int get statusIndex => statusOrder.indexOf(normalizedStatus);

  BreakdownModel copyWith({
    String? id,
    String? reportNumber,
    String? title,
    String? description,
    String? status,
    String? severity,
    String? assetType,
    String? assetName,
    String? assetId,
    String? componentCategory,
    String? componentType,
    String? componentUnit,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? reportedBy,
    String? reporterName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkStageModel>? workStages,
    List<ApprovalModel>? approvals,
    List<String>? mediaUrls,
    List<RepairMediaModel>? repairMedia,
  }) {
    return BreakdownModel(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      assetType: assetType ?? this.assetType,
      assetName: assetName ?? this.assetName,
      assetId: assetId ?? this.assetId,
      componentCategory: componentCategory ?? this.componentCategory,
      componentType: componentType ?? this.componentType,
      componentUnit: componentUnit ?? this.componentUnit,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workStages: workStages ?? this.workStages,
      approvals: approvals ?? this.approvals,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      repairMedia: repairMedia ?? this.repairMedia,
    );
  }
}

class RepairMediaModel {
  final String id;
  final String stage;
  final String mediaUrl;
  final String mediaType;
  final String status;
  final DateTime? capturedAt;

  RepairMediaModel({
    required this.id,
    required this.stage,
    required this.mediaUrl,
    required this.mediaType,
    this.status = 'pending',
    this.capturedAt,
  });

  factory RepairMediaModel.fromJson(Map<String, dynamic> json) {
    return RepairMediaModel(
      id: json['id']?.toString() ?? '',
      stage: json['stage'] ?? '',
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'photo',
      status: json['status'] ?? 'pending',
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'])
          : null,
    );
  }
}

class WorkStageModel {
  final String id;
  final int stageNumber;
  final String title;
  final String? description;
  final String status;
  final DateTime? createdAt;

  WorkStageModel({
    required this.id,
    required this.stageNumber,
    required this.title,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory WorkStageModel.fromJson(Map<String, dynamic> json) {
    return WorkStageModel(
      id: json['id']?.toString() ?? '',
      stageNumber: json['stage_number'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class ApprovalModel {
  final String id;
  final String status;
  final String? approverName;
  final String? approverRole;
  final String? comments;
  final DateTime? approvedAt;

  ApprovalModel({
    required this.id,
    required this.status,
    this.approverName,
    this.approverRole,
    this.comments,
    this.approvedAt,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      approverName: json['approver']?['name'],
      approverRole: json['approver']?['role'],
      comments: json['comments'],
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : null,
    );
  }
}
