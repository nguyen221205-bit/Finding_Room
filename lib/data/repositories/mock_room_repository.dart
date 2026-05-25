import '../../domain/entities/room_entity.dart';
import '../mock/mock_rooms.dart';
import 'room_repository.dart';

class MockRoomRepository implements RoomRepository {
  @override
  Future<List<RoomEntity>> fetchRooms() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return MockRooms.all();
  }
}
