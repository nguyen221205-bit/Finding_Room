class NotificationPreferencesEntity {
  final bool verificationNotificationsEnabled;
  final bool roomApprovalNotificationsEnabled;
  final bool appointmentNotificationsEnabled;

  const NotificationPreferencesEntity({
    this.verificationNotificationsEnabled = true,
    this.roomApprovalNotificationsEnabled = true,
    this.appointmentNotificationsEnabled = true,
  });

  NotificationPreferencesEntity copyWith({
    bool? verificationNotificationsEnabled,
    bool? roomApprovalNotificationsEnabled,
    bool? appointmentNotificationsEnabled,
  }) {
    return NotificationPreferencesEntity(
      verificationNotificationsEnabled:
          verificationNotificationsEnabled ??
          this.verificationNotificationsEnabled,
      roomApprovalNotificationsEnabled:
          roomApprovalNotificationsEnabled ??
          this.roomApprovalNotificationsEnabled,
      appointmentNotificationsEnabled:
          appointmentNotificationsEnabled ??
          this.appointmentNotificationsEnabled,
    );
  }
}
