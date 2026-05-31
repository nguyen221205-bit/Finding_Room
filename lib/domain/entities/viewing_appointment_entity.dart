import 'app_enums.dart';

class ViewingAppointmentEntity {
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

  const ViewingAppointmentEntity({
    required this.id,
    required this.appointmentCode,
    required this.roomId,
    required this.landlordId,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.numberOfPeople,
    required this.appointmentTime,
    this.status = AppointmentStatus.pending,
    required this.createdAt,
    this.note,
  });

  ViewingAppointmentEntity copyWith({
    String? id,
    String? appointmentCode,
    String? roomId,
    String? landlordId,
    String? tenantId,
    String? tenantName,
    String? tenantPhone,
    int? numberOfPeople,
    DateTime? appointmentTime,
    AppointmentStatus? status,
    DateTime? createdAt,
    String? note,
    bool clearNote = false,
  }) {
    return ViewingAppointmentEntity(
      id: id ?? this.id,
      appointmentCode: appointmentCode ?? this.appointmentCode,
      roomId: roomId ?? this.roomId,
      landlordId: landlordId ?? this.landlordId,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: clearNote ? null : note ?? this.note,
    );
  }
}
