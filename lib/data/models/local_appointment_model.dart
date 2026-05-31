import '../../domain/entities/app_enums.dart';
import '../../domain/entities/viewing_appointment_entity.dart';

class LocalAppointmentModel {
  final String id;
  final String appointmentCode;
  final String roomId;
  final String landlordId;
  final String tenantId;
  final String tenantName;
  final String tenantPhone;
  final int numberOfPeople;
  final DateTime appointmentTime;
  final AppointmentStatus status;
  final DateTime createdAt;
  final String? note;

  const LocalAppointmentModel({
    required this.id,
    required this.appointmentCode,
    required this.roomId,
    required this.landlordId,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.numberOfPeople,
    required this.appointmentTime,
    required this.status,
    required this.createdAt,
    this.note,
  });

  ViewingAppointmentEntity toEntity() {
    return ViewingAppointmentEntity(
      id: id,
      appointmentCode: appointmentCode,
      roomId: roomId,
      landlordId: landlordId,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      numberOfPeople: numberOfPeople,
      appointmentTime: appointmentTime,
      status: status,
      createdAt: createdAt,
      note: note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'appointmentCode': appointmentCode,
      'roomId': roomId,
      'landlordId': landlordId,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'numberOfPeople': numberOfPeople,
      'appointmentTime': appointmentTime.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  static LocalAppointmentModel fromMap(Map<dynamic, dynamic> map) {
    return LocalAppointmentModel(
      id: map['id'] as String? ?? '',
      appointmentCode: map['appointmentCode'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      landlordId: map['landlordId'] as String? ?? '',
      tenantId: map['tenantId'] as String? ?? '',
      tenantName: map['tenantName'] as String? ?? '',
      tenantPhone: map['tenantPhone'] as String? ?? '',
      numberOfPeople: map['numberOfPeople'] as int? ?? 1,
      appointmentTime: map['appointmentTime'] != null
          ? DateTime.tryParse(map['appointmentTime'] as String) ??
                DateTime.now()
          : DateTime.now(),
      status: _statusFromName(map['status'] as String? ?? 'pending'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }

  static LocalAppointmentModel fromEntity(ViewingAppointmentEntity entity) {
    return LocalAppointmentModel(
      id: entity.id,
      appointmentCode: entity.appointmentCode,
      roomId: entity.roomId,
      landlordId: entity.landlordId,
      tenantId: entity.tenantId,
      tenantName: entity.tenantName,
      tenantPhone: entity.tenantPhone,
      numberOfPeople: entity.numberOfPeople,
      appointmentTime: entity.appointmentTime,
      status: entity.status,
      createdAt: entity.createdAt,
      note: entity.note,
    );
  }

  static AppointmentStatus _statusFromName(String name) {
    return AppointmentStatus.values.firstWhere(
      (AppointmentStatus s) => s.name == name,
      orElse: () => AppointmentStatus.pending,
    );
  }
}
