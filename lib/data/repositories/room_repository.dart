import '../../domain/entities/room_entity.dart';

abstract class RoomRepository {
  Future<List<RoomEntity>> fetchRooms();
}
