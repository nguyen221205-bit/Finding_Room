import 'app_enums.dart';

class LandlordRequestEntity {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String identityNumber;
  final String currentAddress;
  final String identityImageUrl;
  final String requestMessage;
  final LandlordRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  // New multi-step verification fields
  final String verificationType;
  final String frontIdImage;
  final String backIdImage;
  final String selfieWithIdImage;
  final String? taxCode;
  final String purpose;

  const LandlordRequestEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.identityNumber,
    required this.currentAddress,
    required this.identityImageUrl,
    required this.requestMessage,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
    this.verificationType = 'personal',
    this.frontIdImage = '',
    this.backIdImage = '',
    this.selfieWithIdImage = '',
    this.taxCode,
    this.purpose = '',
  });

  LandlordRequestEntity copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? identityNumber,
    String? currentAddress,
    String? identityImageUrl,
    String? requestMessage,
    LandlordRequestStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    bool clearRejectionReason = false,
    String? verificationType,
    String? frontIdImage,
    String? backIdImage,
    String? selfieWithIdImage,
    String? taxCode,
    String? purpose,
  }) {
    return LandlordRequestEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      identityNumber: identityNumber ?? this.identityNumber,
      currentAddress: currentAddress ?? this.currentAddress,
      identityImageUrl: identityImageUrl ?? this.identityImageUrl,
      requestMessage: requestMessage ?? this.requestMessage,
      status: status ?? this.status,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      verificationType: verificationType ?? this.verificationType,
      frontIdImage: frontIdImage ?? this.frontIdImage,
      backIdImage: backIdImage ?? this.backIdImage,
      selfieWithIdImage: selfieWithIdImage ?? this.selfieWithIdImage,
      taxCode: taxCode ?? this.taxCode,
      purpose: purpose ?? this.purpose,
    );
  }
}
