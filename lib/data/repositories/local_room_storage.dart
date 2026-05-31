import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../domain/entities/room_entity.dart';
import '../mock/mock_rooms.dart';
import '../models/local_room_model.dart';
import 'room_repository.dart';

class LocalRoomStorage implements RoomRepository {
  Box<dynamic> get _roomsBox => Hive.box<dynamic>(HiveBoxes.rooms);

  @override
  Future<List<RoomEntity>> fetchRooms() async {
    await seedIfNeeded();

    // Tương thích ngược: tự động quét sinh roomCode nếu bị thiếu
    final List<dynamic> keys = _roomsBox.keys.toList();
    for (final dynamic key in keys) {
      final dynamic value = _roomsBox.get(key);
      if (value is Map<dynamic, dynamic>) {
        if (value['roomCode'] == null ||
            (value['roomCode'] as String).isEmpty) {
          final String newCode = BusinessCodeGenerator.generate(
            prefix: 'ROOM',
            box: _roomsBox,
            codeExtractor: (entry) =>
                entry is Map ? entry['roomCode'] as String? : null,
          );
          final Map<String, dynamic> updatedMap = Map<String, dynamic>.from(
            value,
          );
          updatedMap['roomCode'] = newCode;
          await _roomsBox.put(key, updatedMap);
        }
      }
    }

    return _roomsBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(LocalRoomModel.fromMap)
        .toList(growable: false);
  }

  Future<void> seedIfNeeded() async {
    if (_roomsBox.isNotEmpty) return;
    await saveAll(MockRooms.all());
  }

  Future<void> saveAll(List<RoomEntity> rooms) async {
    await _roomsBox.clear();
    final Map<String, dynamic> data = <String, dynamic>{};
    for (final RoomEntity room in rooms) {
      data[room.id] = LocalRoomModel(room).toMap();
    }
    await _roomsBox.putAll(data);
  }

  Future<RoomEntity> upsertRoom(RoomEntity room) async {
    RoomEntity updatedRoom = room;
    if (room.roomCode.isEmpty) {
      final String newCode = BusinessCodeGenerator.generate(
        prefix: 'ROOM',
        box: _roomsBox,
        codeExtractor: (entry) =>
            entry is Map ? entry['roomCode'] as String? : null,
      );
      updatedRoom = room.copyWith(roomCode: newCode);
    }
    await _roomsBox.put(updatedRoom.id, LocalRoomModel(updatedRoom).toMap());
    return updatedRoom;
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsBox.delete(roomId);
  }
}
