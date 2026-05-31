import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/id_generator.dart';
import '../../data/repositories/local_appointment_storage.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/viewing_appointment_entity.dart';

class AppointmentProvider extends ChangeNotifier {
  final LocalAppointmentStorage _storage;

  AppointmentProvider({LocalAppointmentStorage? storage})
    : _storage = storage ?? LocalAppointmentStorage();

  List<ViewingAppointmentEntity> _appointments = <ViewingAppointmentEntity>[];
  bool _isLoading = false;
  String? _error;

  List<ViewingAppointmentEntity> get appointments =>
      List<ViewingAppointmentEntity>.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAppointmentsForLandlord(String landlordId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _storage.loadAppointmentsByLandlord(landlordId);
    } catch (e) {
      _error = 'Không thể tải danh sách lịch hẹn.';
      _appointments = <ViewingAppointmentEntity>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointmentsForTenant(String tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _storage.loadAppointmentsByTenant(tenantId);
    } catch (e) {
      _error = 'Không thể tải danh sách lịch hẹn.';
      _appointments = <ViewingAppointmentEntity>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ViewingAppointmentEntity?> createAppointment({
    required String roomId,
    required String landlordId,
    required String tenantId,
    required String tenantName,
    required String tenantPhone,
    required int numberOfPeople,
    required DateTime appointmentTime,
    String? note,
  }) async {
    _error = null;

    final String trimmedName = tenantName.trim();
    final String trimmedPhone = tenantPhone.trim();

    if (trimmedName.isEmpty) {
      _error = 'Họ và tên không được để trống.';
      notifyListeners();
      return null;
    }
    if (trimmedPhone.isEmpty) {
      _error = 'Số điện thoại không được để trống.';
      notifyListeners();
      return null;
    }
    if (numberOfPeople <= 0) {
      _error = 'Số người hẹn phải lớn hơn 0.';
      notifyListeners();
      return null;
    }

    final ViewingAppointmentEntity appointment = ViewingAppointmentEntity(
      id: IdGenerator.generate('apt'),
      appointmentCode: '',
      roomId: roomId,
      landlordId: landlordId,
      tenantId: tenantId,
      tenantName: trimmedName,
      tenantPhone: trimmedPhone,
      numberOfPeople: numberOfPeople,
      appointmentTime: appointmentTime,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      note: note?.trim(),
    );

    try {
      final ViewingAppointmentEntity savedAppointment = await _storage
          .saveAppointment(appointment);
      _appointments.insert(0, savedAppointment);
      notifyListeners();
      return savedAppointment;
    } catch (e) {
      _error = 'Không thể tạo cuộc hẹn: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> approveAppointment(String appointmentId) async {
    _error = null;
    try {
      await _storage.approveAppointment(appointmentId);
      final int index = _appointments.indexWhere(
        (ViewingAppointmentEntity a) => a.id == appointmentId,
      );
      if (index >= 0) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.approved,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể phê duyệt cuộc hẹn.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAppointment(String appointmentId) async {
    _error = null;
    try {
      await _storage.rejectAppointment(appointmentId);
      final int index = _appointments.indexWhere(
        (ViewingAppointmentEntity a) => a.id == appointmentId,
      );
      if (index >= 0) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.rejected,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể từ chối cuộc hẹn.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointmentByTenant(String appointmentId) async {
    _error = null;
    try {
      final ViewingAppointmentEntity? apt = await _storage.getAppointmentById(
        appointmentId,
      );
      if (apt == null) return false;

      if (apt.status != AppointmentStatus.pending &&
          apt.status != AppointmentStatus.approved) {
        _error = 'Lịch hẹn không ở trạng thái hợp lệ để hủy.';
        notifyListeners();
        return false;
      }

      final ViewingAppointmentEntity updated = apt.copyWith(
        status: AppointmentStatus.cancelledByTenant,
      );
      await _storage.saveAppointment(updated);

      final int index = _appointments.indexWhere(
        (ViewingAppointmentEntity a) => a.id == appointmentId,
      );
      if (index >= 0) {
        _appointments[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể hủy lịch hẹn.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointmentByLandlord(String appointmentId) async {
    _error = null;
    try {
      final ViewingAppointmentEntity? apt = await _storage.getAppointmentById(
        appointmentId,
      );
      if (apt == null) return false;

      if (apt.status != AppointmentStatus.approved) {
        _error = 'Chủ nhà chỉ có thể hủy lịch hẹn đã được xác nhận.';
        notifyListeners();
        return false;
      }

      final ViewingAppointmentEntity updated = apt.copyWith(
        status: AppointmentStatus.cancelledByLandlord,
      );
      await _storage.saveAppointment(updated);

      final int index = _appointments.indexWhere(
        (ViewingAppointmentEntity a) => a.id == appointmentId,
      );
      if (index >= 0) {
        _appointments[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể hủy lịch hẹn.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeAppointment(String appointmentId) async {
    _error = null;
    try {
      final ViewingAppointmentEntity? apt = await _storage.getAppointmentById(
        appointmentId,
      );
      if (apt == null) return false;

      if (apt.status != AppointmentStatus.approved) {
        _error = 'Chỉ có thể hoàn thành lịch hẹn đã được xác nhận.';
        notifyListeners();
        return false;
      }

      final ViewingAppointmentEntity updated = apt.copyWith(
        status: AppointmentStatus.completed,
      );
      await _storage.saveAppointment(updated);

      final int index = _appointments.indexWhere(
        (ViewingAppointmentEntity a) => a.id == appointmentId,
      );
      if (index >= 0) {
        _appointments[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể hoàn thành lịch hẹn.';
      notifyListeners();
      return false;
    }
  }

  Future<List<ViewingAppointmentEntity>> cancelAppointmentsForRoomByAdmin(
    String roomId,
  ) async {
    final List<ViewingAppointmentEntity> cancelledList =
        <ViewingAppointmentEntity>[];
    try {
      cancelledList.addAll(
        await _storage.cancelOpenAppointmentsForRoomByAdmin(roomId),
      );

      // Đồng bộ RAM
      for (int i = 0; i < _appointments.length; i++) {
        if (_appointments[i].roomId == roomId &&
            (_appointments[i].status == AppointmentStatus.pending ||
                _appointments[i].status == AppointmentStatus.approved)) {
          _appointments[i] = _appointments[i].copyWith(
            status: AppointmentStatus.cancelledByAdmin,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error auto-cancelling appointments for room by admin: $e');
      }
    }
    return cancelledList;
  }

  Future<List<ViewingAppointmentEntity>> cancelAppointmentsForLandlordByAdmin(
    String landlordId,
  ) async {
    final List<ViewingAppointmentEntity> cancelledList =
        <ViewingAppointmentEntity>[];
    try {
      cancelledList.addAll(
        await _storage.cancelOpenAppointmentsForLandlordByAdmin(landlordId),
      );

      // Đồng bộ RAM
      for (int i = 0; i < _appointments.length; i++) {
        if (_appointments[i].landlordId == landlordId &&
            (_appointments[i].status == AppointmentStatus.pending ||
                _appointments[i].status == AppointmentStatus.approved)) {
          _appointments[i] = _appointments[i].copyWith(
            status: AppointmentStatus.cancelledByAdmin,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error auto-cancelling appointments for landlord by admin: $e');
      }
    }
    return cancelledList;
  }
}
