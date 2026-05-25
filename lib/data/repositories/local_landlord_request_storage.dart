import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../domain/entities/landlord_request_entity.dart';
import '../mock/mock_landlord_requests.dart';
import '../models/local_landlord_request_model.dart';

class LocalLandlordRequestStorage {
  Box<dynamic> get _requestsBox =>
      Hive.box<dynamic>(HiveBoxes.landlordRequests);

  Future<List<LandlordRequestEntity>> fetchRequests() async {
    await seedIfNeeded();
    return _requestsBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(LocalLandlordRequestModel.fromMap)
        .toList(growable: false);
  }

  Future<void> seedIfNeeded() async {
    if (_requestsBox.isNotEmpty) return;
    await saveAll(MockLandlordRequests.all());
  }

  Future<LandlordRequestEntity?> getByUserId(String userId) async {
    await seedIfNeeded();
    for (final dynamic value in _requestsBox.values) {
      if (value is! Map<dynamic, dynamic>) continue;

      final LandlordRequestEntity request = LocalLandlordRequestModel.fromMap(
        value,
      );
      if (request.userId == userId) {
        return request;
      }
    }

    return null;
  }

  Future<void> saveAll(List<LandlordRequestEntity> requests) async {
    await _requestsBox.clear();
    for (final LandlordRequestEntity request in requests) {
      await upsertRequest(request);
    }
  }

  Future<void> upsertRequest(LandlordRequestEntity request) async {
    await _requestsBox.put(
      request.id,
      LocalLandlordRequestModel(request).toMap(),
    );
  }
}
