/// Response for Trip Status update (/crew/trips/{id}/status)
class CrewTripStatusResponse {
  final bool success;
  final String message;
  final CrewTripStatusData? data;
  final Map<String, dynamic>? errors;

  CrewTripStatusResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewTripStatusResponse.fromJson(Map<String, dynamic> json) {
    return CrewTripStatusResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewTripStatusData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
        if (errors != null) 'errors': errors,
      };

  String get firstErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      for (final key in errors!.keys) {
        final val = errors![key];
        if (val is List && val.isNotEmpty) {
          return val.first.toString();
        } else if (val is String && val.isNotEmpty) {
          return val;
        }
      }
    }
    return message.isNotEmpty ? message : 'Failed to update trip status.';
  }
}

/// Data returned when trip status is updated
class CrewTripStatusData {
  final int scheduleId;
  final String status;
  final int delayMinutes;
  final String? operationalNotes;
  final String? updatedAt;

  CrewTripStatusData({
    required this.scheduleId,
    required this.status,
    required this.delayMinutes,
    this.operationalNotes,
    this.updatedAt,
  });

  factory CrewTripStatusData.fromJson(Map<String, dynamic> json) {
    return CrewTripStatusData(
      scheduleId: _parseInt(json['schedule_id']) ?? 19,
      status: json['status']?.toString() ?? 'in_transit',
      delayMinutes: _parseInt(json['delay_minutes']) ?? 0,
      operationalNotes: json['operational_notes']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schedule_id': scheduleId,
        'status': status,
        'delay_minutes': delayMinutes,
        'operational_notes': operationalNotes,
        'updated_at': updatedAt,
      };
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
