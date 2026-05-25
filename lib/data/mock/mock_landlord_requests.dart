import '../../domain/entities/app_enums.dart';
import '../../domain/entities/landlord_request_entity.dart';

class MockLandlordRequests {
  static final List<LandlordRequestEntity> _requests = <LandlordRequestEntity>[
    LandlordRequestEntity(
      id: 'lr1',
      userId: 'u_user_1',
      fullName: 'Nguyen Van An',
      phoneNumber: '+84901234567',
      identityNumber: '079203004512',
      currentAddress: '24 Nguyen Trai, District 1, Ho Chi Minh City',
      identityImageUrl:
          'https://images.unsplash.com/photo-1586953208448-b95a79798f07?auto=format&fit=crop&w=1200&q=60',
      requestMessage:
          'I own two rental studios and would like to publish verified listings.',
      status: LandlordRequestStatus.pending,
      rejectionReason: null,
      createdAt: DateTime(2026, 4, 20),
    ),
    LandlordRequestEntity(
      id: 'lr2',
      userId: 'u_landlord_2',
      fullName: 'Tran Thi Linh',
      phoneNumber: '+84908886655',
      identityNumber: '031198008877',
      currentAddress: '88 Le Loi, District 1, Ho Chi Minh City',
      identityImageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1200&q=60',
      requestMessage:
          'I manage verified rooms near District 1 and want to help tenants contact me directly.',
      status: LandlordRequestStatus.approved,
      rejectionReason: null,
      createdAt: DateTime(2026, 4, 18),
    ),
    LandlordRequestEntity(
      id: 'lr3',
      userId: 'u_user_3',
      fullName: 'Pham Minh Hai',
      phoneNumber: '+84909990011',
      identityNumber: '001199002233',
      currentAddress: '5 Pham Van Dong, Thu Duc, Ho Chi Minh City',
      identityImageUrl:
          'https://images.unsplash.com/photo-1568667256549-094345857637?auto=format&fit=crop&w=1200&q=60',
      requestMessage:
          'I want to list several budget rooms for students near the university.',
      status: LandlordRequestStatus.rejected,
      rejectionReason: 'Identity information is missing. Please resubmit.',
      createdAt: DateTime(2026, 4, 16),
    ),
  ];

  static List<LandlordRequestEntity> all() {
    return List<LandlordRequestEntity>.from(_requests);
  }

  static LandlordRequestEntity? getByUserId(String userId) {
    try {
      return _requests.firstWhere(
        (LandlordRequestEntity request) => request.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  static void saveAll(List<LandlordRequestEntity> requests) {
    _requests
      ..clear()
      ..addAll(requests);
  }
}
