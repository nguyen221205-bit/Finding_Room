enum UserRole { user, landlord, admin }

enum ActiveUserMode { renter, landlord }

enum LandlordRequestStatus { pending, approved, rejected }

enum RoomStatus { pending, approved, rejected, hiddenByAdmin }

enum RoomAvailability { available, rented }

enum NotificationType {
  verificationApproved,
  verificationRejected,
  roomApproved,
  roomRejected,
  chatMessage,
  appointmentCreated,
  appointmentApproved,
  appointmentRejected,
  roomHiddenByAdmin,
  landlordPrivilegeRevoked,
  appointmentCompleted,
  appointmentCancelledByTenant,
  appointmentCancelledByLandlord,
  appointmentCancelledByAdmin,
}

enum AppointmentStatus {
  pending,
  approved,
  rejected,
  completed,
  cancelledByTenant,
  cancelledByLandlord,
  cancelledByAdmin,
}
