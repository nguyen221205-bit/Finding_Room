import '../../domain/entities/app_enums.dart';
import '../../domain/entities/landlord_request_entity.dart';

class LocalLandlordRequestModel {
  final LandlordRequestEntity request;

  const LocalLandlordRequestModel(this.request);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': request.id,
      'userId': request.userId,
      'fullName': request.fullName,
      'phoneNumber': request.phoneNumber,
      'identityNumber': request.identityNumber,
      'currentAddress': request.currentAddress,
      'identityImageUrl': request.identityImageUrl,
      'requestMessage': request.requestMessage,
      'status': request.status.name,
      'rejectionReason': request.rejectionReason,
      'createdAt': request.createdAt.toIso8601String(),
      'verificationType': request.verificationType,
      'frontIdImage': request.frontIdImage,
      'backIdImage': request.backIdImage,
      'selfieWithIdImage': request.selfieWithIdImage,
      'taxCode': request.taxCode,
      'purpose': request.purpose,
    };
  }

  static LandlordRequestEntity fromMap(Map<dynamic, dynamic> map) {
    return LandlordRequestEntity(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      identityNumber: map['identityNumber'] as String? ?? '',
      currentAddress: map['currentAddress'] as String? ?? '',
      identityImageUrl: map['identityImageUrl'] as String? ?? '',
      requestMessage: map['requestMessage'] as String? ?? '',
      status: _statusFromName(map['status'] as String?),
      rejectionReason: map['rejectionReason'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      verificationType: map['verificationType'] as String? ?? 'personal',
      frontIdImage: map['frontIdImage'] as String? ?? '',
      backIdImage: map['backIdImage'] as String? ?? '',
      selfieWithIdImage: map['selfieWithIdImage'] as String? ?? '',
      taxCode: map['taxCode'] as String?,
      purpose: map['purpose'] as String? ?? '',
    );
  }

  static LandlordRequestStatus _statusFromName(String? name) {
    return LandlordRequestStatus.values.firstWhere(
      (LandlordRequestStatus status) => status.name == name,
      orElse: () => LandlordRequestStatus.pending,
    );
  }
}
