import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../domain/entities/room_entity.dart';
import '../mock/mock_rooms.dart';
import '../models/local_room_model.dart';
import 'room_repository.dart';

class LocalRoomStorage implements RoomRepository {
  Box<dynamic> get _roomsBox => Hive.box<dynamic>(HiveBoxes.rooms);

  @override
  Future<List<RoomEntity>> fetchRooms() async {
    await seedIfNeeded();
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

  Future<void> upsertRoom(RoomEntity room) async {
    await _roomsBox.put(room.id, LocalRoomModel(room).toMap());
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsBox.delete(roomId);
  }
}
