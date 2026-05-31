import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../domain/entities/landlord_request_entity.dart';
import '../mock/mock_landlord_requests.dart';
import '../models/local_landlord_request_model.dart';

class LocalLandlordRequestStorage {
  Box<dynamic> get _requestsBox =>
      Hive.box<dynamic>(HiveBoxes.landlordRequests);

  Future<void> _ensureCodes() async {
    final List<dynamic> keys = _requestsBox.keys.toList();
    for (final dynamic key in keys) {
      final dynamic value = _requestsBox.get(key);
      if (value is Map<dynamic, dynamic>) {
        if (value['verificationCode'] == null ||
            (value['verificationCode'] as String).isEmpty) {
          final String newCode = BusinessCodeGenerator.generate(
            prefix: 'VER',
            box: _requestsBox,
            codeExtractor: (entry) =>
                entry is Map ? entry['verificationCode'] as String? : null,
          );
          final Map<String, dynamic> updatedMap = Map<String, dynamic>.from(
            value,
          );
          updatedMap['verificationCode'] = newCode;
          await _requestsBox.put(key, updatedMap);
        }
      }
    }
  }

  Future<List<LandlordRequestEntity>> fetchRequests() async {
    await seedIfNeeded();
    await _ensureCodes();
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
    await _ensureCodes();
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

  Future<LandlordRequestEntity> upsertRequest(
    LandlordRequestEntity request,
  ) async {
    LandlordRequestEntity updatedRequest = request;
    if (request.verificationCode.isEmpty) {
      final String newCode = BusinessCodeGenerator.generate(
        prefix: 'VER',
        box: _requestsBox,
        codeExtractor: (entry) =>
            entry is Map ? entry['verificationCode'] as String? : null,
      );
      updatedRequest = request.copyWith(verificationCode: newCode);
    }
    await _requestsBox.put(
      updatedRequest.id,
      LocalLandlordRequestModel(updatedRequest).toMap(),
    );
    return updatedRequest;
  }
}
