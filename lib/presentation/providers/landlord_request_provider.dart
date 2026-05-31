import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/local_landlord_request_storage.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/landlord_request_entity.dart';

class LandlordRequestProvider extends ChangeNotifier {
  final LocalLandlordRequestStorage _storage;

  LandlordRequestProvider({LocalLandlordRequestStorage? storage})
    : _storage = storage ?? LocalLandlordRequestStorage();

  bool _isLoading = false;
  String? _error;

  final List<LandlordRequestEntity> _requests = <LandlordRequestEntity>[];

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<LandlordRequestEntity> get requests =>
      List<LandlordRequestEntity>.unmodifiable(_requests);

  List<LandlordRequestEntity> get pendingRequests => _requests
      .where(
        (LandlordRequestEntity request) =>
            request.status == LandlordRequestStatus.pending,
      )
      .toList();

  bool get hasLoaded => _requests.isNotEmpty || _error != null;

  Future<void> loadRequestsIfNeeded() async {
    if (_isLoading || hasLoaded) return;
    await loadRequests();
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final List<LandlordRequestEntity> result = await _storage.fetchRequests();
      _requests
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = 'Failed to load landlord requests.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LandlordRequestEntity? getUserRequest(String userId) {
    try {
      return _requests.firstWhere(
        (LandlordRequestEntity request) => request.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitRequest({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String identityNumber,
    required String currentAddress,
    required String identityImageUrl,
    required String requestMessage,
    String verificationType = 'personal',
    String frontIdImage = '',
    String backIdImage = '',
    String selfieWithIdImage = '',
    String? taxCode,
    String purpose = '',
  }) async {
    _error = null;

    final String trimmedFullName = fullName.trim();
    final String trimmedPhoneNumber = phoneNumber.trim();
    final String trimmedIdentityNumber = identityNumber.trim();
    final String trimmedCurrentAddress = currentAddress.trim();
    final String trimmedIdentityImageUrl = identityImageUrl.trim();
    final String trimmedRequestMessage = requestMessage.trim();

    final String trimmedFrontIdImage = frontIdImage.trim().isEmpty
        ? trimmedIdentityImageUrl
        : frontIdImage.trim();
    final String trimmedBackIdImage = backIdImage.trim();
    final String trimmedSelfieWithIdImage = selfieWithIdImage.trim();
    final String trimmedPurpose = purpose.trim().isEmpty
        ? trimmedRequestMessage
        : purpose.trim();

    final bool isInvalid =
        userId.trim().isEmpty ||
        trimmedFullName.isEmpty ||
        trimmedPhoneNumber.isEmpty ||
        trimmedIdentityNumber.isEmpty ||
        trimmedCurrentAddress.isEmpty ||
        (trimmedFrontIdImage.isEmpty && trimmedIdentityImageUrl.isEmpty) ||
        (trimmedPurpose.isEmpty && trimmedRequestMessage.isEmpty);

    if (isInvalid) {
      _error = 'Please complete all verification information.';
      notifyListeners();
      return false;
    }

    final LandlordRequestEntity? existing = getUserRequest(userId);

    if (existing == null) {
      final LandlordRequestEntity request = LandlordRequestEntity(
        id: IdGenerator.generate('lr'),
        userId: userId.trim(),
        fullName: trimmedFullName,
        phoneNumber: trimmedPhoneNumber,
        identityNumber: trimmedIdentityNumber,
        currentAddress: trimmedCurrentAddress,
        identityImageUrl: trimmedFrontIdImage.isNotEmpty
            ? trimmedFrontIdImage
            : trimmedIdentityImageUrl,
        requestMessage: trimmedPurpose.isNotEmpty
            ? trimmedPurpose
            : trimmedRequestMessage,
        status: LandlordRequestStatus.pending,
        rejectionReason: null,
        createdAt: DateTime.now(),
        verificationType: verificationType,
        frontIdImage: trimmedFrontIdImage,
        backIdImage: trimmedBackIdImage,
        selfieWithIdImage: trimmedSelfieWithIdImage,
        taxCode: taxCode?.trim(),
        purpose: trimmedPurpose,
      );
      try {
        final LandlordRequestEntity savedRequest = await _storage.upsertRequest(
          request,
        );
        _requests.insert(0, savedRequest);
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    }

    if (existing.status == LandlordRequestStatus.pending ||
        existing.status == LandlordRequestStatus.approved) {
      _error = existing.status == LandlordRequestStatus.pending
          ? 'You already have a pending landlord request.'
          : 'Your landlord request has already been approved.';
      notifyListeners();
      return false;
    }

    final int index = _requests.indexWhere(
      (LandlordRequestEntity request) => request.id == existing.id,
    );
    if (index < 0) return false;

    final LandlordRequestEntity updatedRequest = existing.copyWith(
      fullName: trimmedFullName,
      phoneNumber: trimmedPhoneNumber,
      identityNumber: trimmedIdentityNumber,
      currentAddress: trimmedCurrentAddress,
      identityImageUrl: trimmedFrontIdImage.isNotEmpty
          ? trimmedFrontIdImage
          : trimmedIdentityImageUrl,
      requestMessage: trimmedPurpose.isNotEmpty
          ? trimmedPurpose
          : trimmedRequestMessage,
      status: LandlordRequestStatus.pending,
      createdAt: DateTime.now(),
      clearRejectionReason: true,
      verificationType: verificationType,
      frontIdImage: trimmedFrontIdImage,
      backIdImage: trimmedBackIdImage,
      selfieWithIdImage: trimmedSelfieWithIdImage,
      taxCode: taxCode?.trim(),
      purpose: trimmedPurpose,
    );
    try {
      final LandlordRequestEntity savedRequest = await _storage.upsertRequest(
        updatedRequest,
      );
      _requests[index] = savedRequest;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> approveRequest(String requestId) async {
    final int index = _requests.indexWhere(
      (LandlordRequestEntity request) => request.id == requestId,
    );
    if (index < 0) return false;

    final LandlordRequestEntity updated = _requests[index].copyWith(
      status: LandlordRequestStatus.approved,
      clearRejectionReason: true,
    );
    try {
      final LandlordRequestEntity saved = await _storage.upsertRequest(updated);
      _requests[index] = saved;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    final int index = _requests.indexWhere(
      (LandlordRequestEntity request) => request.id == requestId,
    );
    if (index < 0) return false;

    final String trimmedReason = reason.trim();
    final LandlordRequestEntity updated = _requests[index].copyWith(
      status: LandlordRequestStatus.rejected,
      rejectionReason: trimmedReason.isEmpty
          ? 'Rejected by admin.'
          : trimmedReason,
    );
    try {
      final LandlordRequestEntity saved = await _storage.upsertRequest(updated);
      _requests[index] = saved;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> revokeVerificationByUserId({
    required String userId,
    required String reason,
  }) async {
    final LandlordRequestEntity? existing = getUserRequest(userId);
    if (existing == null) {
      return true;
    }
    return rejectRequest(requestId: existing.id, reason: reason);
  }
}
