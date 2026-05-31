import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/viewing_appointment_entity.dart';
import '../models/local_appointment_model.dart';

class LocalAppointmentStorage {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.appointments);

  Future<ViewingAppointmentEntity> saveAppointment(
    ViewingAppointmentEntity appointment,
  ) async {
    ViewingAppointmentEntity updatedAppointment = appointment;
    if (appointment.appointmentCode.isEmpty) {
      final String code = BusinessCodeGenerator.generate(
        prefix: 'APT',
        box: _box,
        codeExtractor: (dynamic entry) {
          if (entry is Map) {
            return entry['appointmentCode'] as String?;
          }
          return null;
        },
      );
      updatedAppointment = appointment.copyWith(appointmentCode: code);
    }

    final LocalAppointmentModel model = LocalAppointmentModel.fromEntity(
      updatedAppointment,
    );
    await _box.put(updatedAppointment.id, model.toMap());
    return updatedAppointment;
  }

  Future<void> updateAppointment(ViewingAppointmentEntity appointment) async {
    await saveAppointment(appointment);
  }

  Future<List<ViewingAppointmentEntity>> loadAppointmentsByLandlord(
    String landlordId,
  ) async {
    final List<ViewingAppointmentEntity> list = <ViewingAppointmentEntity>[];
    for (final dynamic val in _box.values) {
      if (val is Map) {
        final LocalAppointmentModel model = LocalAppointmentModel.fromMap(val);
        if (model.landlordId == landlordId) {
          list.add(model.toEntity());
        }
      }
    }
    // Sắp xếp lịch hẹn mới nhất lên đầu
    list.sort(
      (ViewingAppointmentEntity a, ViewingAppointmentEntity b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    return list;
  }

  Future<List<ViewingAppointmentEntity>> loadAppointmentsByTenant(
    String tenantId,
  ) async {
    final List<ViewingAppointmentEntity> list = <ViewingAppointmentEntity>[];
    for (final dynamic val in _box.values) {
      if (val is Map) {
        final LocalAppointmentModel model = LocalAppointmentModel.fromMap(val);
        if (model.tenantId == tenantId) {
          list.add(model.toEntity());
        }
      }
    }
    // Sắp xếp lịch hẹn mới nhất lên đầu
    list.sort(
      (ViewingAppointmentEntity a, ViewingAppointmentEntity b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    return list;
  }

  Future<void> approveAppointment(String appointmentId) async {
    final dynamic val = _box.get(appointmentId);
    if (val is Map) {
      final LocalAppointmentModel model = LocalAppointmentModel.fromMap(val);
      final ViewingAppointmentEntity updated = model.toEntity().copyWith(
        status: AppointmentStatus.approved,
      );
      await saveAppointment(updated);
    }
  }

  Future<void> rejectAppointment(String appointmentId) async {
    final dynamic val = _box.get(appointmentId);
    if (val is Map) {
      final LocalAppointmentModel model = LocalAppointmentModel.fromMap(val);
      final ViewingAppointmentEntity updated = model.toEntity().copyWith(
        status: AppointmentStatus.rejected,
      );
      await saveAppointment(updated);
    }
  }

  Future<ViewingAppointmentEntity?> getAppointmentById(String id) async {
    final dynamic val = _box.get(id);
    if (val is Map) {
      return LocalAppointmentModel.fromMap(val).toEntity();
    }
    return null;
  }

  Future<List<ViewingAppointmentEntity>> cancelOpenAppointmentsForRoomByAdmin(
    String roomId,
  ) async {
    final List<ViewingAppointmentEntity> cancelled =
        <ViewingAppointmentEntity>[];
    final List<dynamic> keys = _box.keys.toList();

    for (final dynamic key in keys) {
      final dynamic val = _box.get(key);
      if (val is! Map) continue;

      final ViewingAppointmentEntity appointment =
          LocalAppointmentModel.fromMap(val).toEntity();
      if (appointment.roomId != roomId ||
          !_isOpenForAdminCancellation(appointment.status)) {
        continue;
      }

      final ViewingAppointmentEntity updated = appointment.copyWith(
        status: AppointmentStatus.cancelledByAdmin,
      );
      await saveAppointment(updated);
      cancelled.add(updated);
    }

    return cancelled;
  }

  Future<List<ViewingAppointmentEntity>>
  cancelOpenAppointmentsForLandlordByAdmin(String landlordId) async {
    final List<ViewingAppointmentEntity> cancelled =
        <ViewingAppointmentEntity>[];
    final List<dynamic> keys = _box.keys.toList();

    for (final dynamic key in keys) {
      final dynamic val = _box.get(key);
      if (val is! Map) continue;

      final ViewingAppointmentEntity appointment =
          LocalAppointmentModel.fromMap(val).toEntity();
      if (appointment.landlordId != landlordId ||
          !_isOpenForAdminCancellation(appointment.status)) {
        continue;
      }

      final ViewingAppointmentEntity updated = appointment.copyWith(
        status: AppointmentStatus.cancelledByAdmin,
      );
      await saveAppointment(updated);
      cancelled.add(updated);
    }

    return cancelled;
  }

  bool _isOpenForAdminCancellation(AppointmentStatus status) {
    return status == AppointmentStatus.pending ||
        status == AppointmentStatus.approved;
  }
}
