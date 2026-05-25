import 'package:flutter/foundation.dart';

import '../../domain/entities/room_entity.dart';
import 'room_provider.dart';

class FavoriteProvider extends ChangeNotifier {
  RoomProvider? _roomProvider;

  void attach(RoomProvider roomProvider) {
    _roomProvider = roomProvider;
    notifyListeners();
  }

  List<RoomEntity> get favorites {
    final RoomProvider? rp = _roomProvider;
    if (rp == null) return const <RoomEntity>[];
    return rp.rooms.where((RoomEntity r) => r.isFavorite).toList();
  }

  bool isFavorite(String roomId) {
    final RoomProvider? rp = _roomProvider;
    final RoomEntity? room = rp?.byId(roomId);
    return room?.isFavorite ?? false;
  }

  void toggleFavorite(String roomId) {
    _roomProvider?.toggleFavorite(roomId);
    notifyListeners();
  }

  void removeFavorite(String roomId) {
    if (isFavorite(roomId)) {
      toggleFavorite(roomId);
    }
  }
}
