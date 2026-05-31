import '../../domain/entities/notification_preferences_entity.dart';

class LocalNotificationPreferencesModel {
  final bool verificationNotificationsEnabled;
  final bool roomApprovalNotificationsEnabled;
  final bool appointmentNotificationsEnabled;

  const LocalNotificationPreferencesModel({
    required this.verificationNotificationsEnabled,
    required this.roomApprovalNotificationsEnabled,
    required this.appointmentNotificationsEnabled,
  });

  factory LocalNotificationPreferencesModel.fromEntity(
    NotificationPreferencesEntity entity,
  ) {
    return LocalNotificationPreferencesModel(
      verificationNotificationsEnabled: entity.verificationNotificationsEnabled,
      roomApprovalNotificationsEnabled: entity.roomApprovalNotificationsEnabled,
      appointmentNotificationsEnabled: entity.appointmentNotificationsEnabled,
    );
  }

  NotificationPreferencesEntity toEntity() {
    return NotificationPreferencesEntity(
      verificationNotificationsEnabled: verificationNotificationsEnabled,
      roomApprovalNotificationsEnabled: roomApprovalNotificationsEnabled,
      appointmentNotificationsEnabled: appointmentNotificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'verificationNotificationsEnabled': verificationNotificationsEnabled,
      'roomApprovalNotificationsEnabled': roomApprovalNotificationsEnabled,
      'appointmentNotificationsEnabled': appointmentNotificationsEnabled,
    };
  }

  static LocalNotificationPreferencesModel fromMap(Map<dynamic, dynamic> map) {
    return LocalNotificationPreferencesModel(
      verificationNotificationsEnabled:
          map['verificationNotificationsEnabled'] as bool? ?? true,
      roomApprovalNotificationsEnabled:
          map['roomApprovalNotificationsEnabled'] as bool? ?? true,
      appointmentNotificationsEnabled:
          map['appointmentNotificationsEnabled'] as bool? ?? true,
    );
  }
}
