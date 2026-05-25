import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/room_model.dart';
import '../../data/repositories/local_room_storage.dart';
import '../../domain/entities/app_enums.dart';
import '../../data/repositories/room_repository.dart';
import '../../domain/entities/room_entity.dart';

class RoomFilters {
  final String? district;
  final String? priceOption;
  final Set<String> amenities;
  final String sortBy;

  const RoomFilters({
    required this.district,
    required this.priceOption,
    required this.amenities,
    required this.sortBy,
  });

  factory RoomFilters.initial() => const RoomFilters(
    district: null,
    priceOption: null,
    amenities: <String>{},
    sortBy: 'Mới nhất',
  );

  RoomFilters copyWith({
    String? district,
    bool clearDistrict = false,
    String? priceOption,
    bool clearPriceOption = false,
    Set<String>? amenities,
    String? sortBy,
  }) {
    return RoomFilters(
      district: clearDistrict ? null : (district ?? this.district),
      priceOption: clearPriceOption ? null : (priceOption ?? this.priceOption),
      amenities: amenities ?? this.amenities,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class RoomProvider extends ChangeNotifier {
  final RoomRepository _roomRepository;

  RoomProvider(this._roomRepository);

  bool _isLoading = false;
  String? _error;

  final List<RoomModel> _rooms = <RoomModel>[];
  List<RoomEntity> _filteredRooms = <RoomEntity>[];

  String _searchQuery = '';
  RoomFilters _filters = RoomFilters.initial();

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RoomEntity> get rooms => List<RoomEntity>.unmodifiable(_rooms);
  List<RoomEntity> get filteredRooms =>
      List<RoomEntity>.unmodifiable(_filteredRooms);
  List<RoomEntity> get approvedFilteredRooms => _filteredRooms
      .where((RoomEntity room) => room.status == RoomStatus.approved)
      .toList(growable: false);

  String get searchQuery => _searchQuery;
  RoomFilters get filters => _filters;

  bool get hasLoaded => _rooms.isNotEmpty || _error != null;

  Future<void> loadRoomsIfNeeded() async {
    if (_isLoading || hasLoaded) return;
    await loadRooms();
  }

  Future<void> loadRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<RoomEntity> result = await _roomRepository.fetchRooms();
      _rooms
        ..clear()
        ..addAll(result.map(RoomModel.fromEntity));
      _recomputeFiltered();
    } catch (e) {
      _error = 'Failed to load rooms. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RoomEntity? byId(String id) {
    try {
      return _rooms.firstWhere((RoomModel r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RoomEntity> roomsForOwner(String ownerId) {
    return _rooms
        .where((RoomModel room) => room.ownerId == ownerId)
        .cast<RoomEntity>()
        .toList(growable: false);
  }

  List<RoomEntity> roomsForOwnerByStatus(String ownerId, RoomStatus status) {
    return _rooms
        .where(
          (RoomModel room) => room.ownerId == ownerId && room.status == status,
        )
        .cast<RoomEntity>()
        .toList(growable: false);
  }

  void addRoom({
    required String ownerId,
    required String landlordName,
    required String landlordPhone,
    required String landlordAvatarUrl,
    required String title,
    required int price,
    required String address,
    required double area,
    required String description,
    required List<String> amenities,
    required int capacity,
    required String furniture,
    List<String>? imageUrls,
  }) {
    final RoomModel room = RoomModel(
      id: 'r_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      price: price,
      address: address.trim(),
      area: area,
      imageUrls: imageUrls == null || imageUrls.isEmpty
          ? const <String>[
              'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=60',
            ]
          : imageUrls,
      description: description.trim(),
      amenities: amenities,
      isFavorite: false,
      ownerId: ownerId,
      status: RoomStatus.pending,
      rejectionReason: null,
      capacity: capacity,
      furniture: furniture.trim(),
      landlordName: landlordName,
      landlordPhone: landlordPhone,
      landlordAvatarUrl: landlordAvatarUrl,
    );

    _rooms.insert(0, room);
    _persistRoom(room);
    _recomputeFiltered();
    notifyListeners();
  }

  void updateRoom(RoomEntity room) {
    final int index = _rooms.indexWhere((RoomModel item) => item.id == room.id);
    if (index < 0) return;

    final RoomModel model = RoomModel.fromEntity(room);
    _rooms[index] = model;
    _persistRoom(model);
    _recomputeFiltered();
    notifyListeners();
  }

  void deleteRoom(String roomId) {
    final int index = _rooms.indexWhere((RoomModel room) => room.id == roomId);
    if (index < 0) return;

    _rooms.removeAt(index);
    _deletePersistedRoom(roomId);
    _recomputeFiltered();
    notifyListeners();
  }

  bool approveRoom(String roomId) {
    final int index = _rooms.indexWhere((RoomModel room) => room.id == roomId);
    if (index < 0) return false;

    _rooms[index] = _rooms[index].copyWithModel(
      status: RoomStatus.approved,
      clearRejectionReason: true,
    );
    _persistRoom(_rooms[index]);
    _recomputeFiltered();
    notifyListeners();
    return true;
  }

  bool rejectRoom({required String roomId, required String reason}) {
    final int index = _rooms.indexWhere((RoomModel room) => room.id == roomId);
    if (index < 0) return false;

    final String trimmedReason = reason.trim();
    _rooms[index] = _rooms[index].copyWithModel(
      status: RoomStatus.rejected,
      rejectionReason: trimmedReason.isEmpty
          ? 'Rejected by admin.'
          : trimmedReason,
    );
    _persistRoom(_rooms[index]);
    _recomputeFiltered();
    notifyListeners();
    return true;
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    _recomputeFiltered();
    notifyListeners();
  }

  void setDistrict(String? district) {
    if (district == 'Tất cả') {
      _filters = _filters.copyWith(clearDistrict: true);
    } else {
      _filters = _filters.copyWith(district: district);
    }
    _recomputeFiltered();
    notifyListeners();
  }

  void setPriceOption(String? priceOption) {
    if (priceOption == 'Tất cả') {
      _filters = _filters.copyWith(clearPriceOption: true);
    } else {
      _filters = _filters.copyWith(priceOption: priceOption);
    }
    _recomputeFiltered();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _filters = _filters.copyWith(sortBy: sortBy);
    _recomputeFiltered();
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    final Set<String> next = Set<String>.from(_filters.amenities);
    if (next.contains(amenity)) {
      next.remove(amenity);
    } else {
      next.add(amenity);
    }
    _filters = _filters.copyWith(amenities: next);
    _recomputeFiltered();
    notifyListeners();
  }

  void setAmenities(Set<String> amenities) {
    _filters = _filters.copyWith(amenities: Set<String>.from(amenities));
    _recomputeFiltered();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filters = RoomFilters.initial();
    _recomputeFiltered();
    notifyListeners();
  }

  void toggleFavorite(String roomId) {
    final int index = _rooms.indexWhere((RoomModel r) => r.id == roomId);
    if (index < 0) return;
    final RoomModel current = _rooms[index];
    _rooms[index] = current.copyWithModel(isFavorite: !current.isFavorite);
    _persistRoom(_rooms[index]);
    _recomputeFiltered();
    notifyListeners();
  }

  bool updateAvailability(String roomId, RoomAvailability availability) {
    final int index = _rooms.indexWhere((RoomModel r) => r.id == roomId);
    if (index < 0) return false;
    _rooms[index] = _rooms[index].copyWithModel(availability: availability);
    _persistRoom(_rooms[index]);
    _recomputeFiltered();
    notifyListeners();
    return true;
  }

  void _persistRoom(RoomEntity room) {
    final RoomRepository repository = _roomRepository;
    if (repository is LocalRoomStorage) {
      unawaited(repository.upsertRoom(room));
    }
  }

  void _deletePersistedRoom(String roomId) {
    final RoomRepository repository = _roomRepository;
    if (repository is LocalRoomStorage) {
      unawaited(repository.deleteRoom(roomId));
    }
  }

  void _recomputeFiltered() {
    final String q = _searchQuery.toLowerCase();
    final String? dist = _filters.district;
    final String? priceOpt = _filters.priceOption;
    final Set<String> requiredAmenities = _filters.amenities;

    _filteredRooms = _rooms.where((RoomModel room) {
      final bool matchesQuery = q.isEmpty
          ? true
          : room.title.toLowerCase().contains(q) ||
                room.address.toLowerCase().contains(q);

      bool matchesDistrict = true;
      if (dist != null && dist != 'Tất cả') {
        matchesDistrict = room.address.toLowerCase().contains(dist.toLowerCase()) ||
            room.title.toLowerCase().contains(dist.toLowerCase());
      }

      bool matchesPrice = true;
      if (priceOpt != null && priceOpt != 'Tất cả') {
        if (priceOpt == 'Dưới 3 triệu') {
          matchesPrice = room.price < 3000000;
        } else if (priceOpt == '3 - 5 triệu') {
          matchesPrice = room.price >= 3000000 && room.price <= 5000000;
        } else if (priceOpt == '5 - 8 triệu') {
          matchesPrice = room.price >= 5000000 && room.price <= 8000000;
        } else if (priceOpt == 'Trên 8 triệu') {
          matchesPrice = room.price > 8000000;
        }
      }

      final bool matchesAmenities = requiredAmenities.isEmpty
          ? true
          : requiredAmenities.every((String a) => room.amenities.contains(a));

      return matchesQuery && matchesDistrict && matchesPrice && matchesAmenities;
    }).toList();

    // Sorting
    if (_filters.sortBy == 'Giá tăng dần') {
      _filteredRooms.sort((RoomEntity a, RoomEntity b) => a.price.compareTo(b.price));
    } else if (_filters.sortBy == 'Giá giảm dần') {
      _filteredRooms.sort((RoomEntity a, RoomEntity b) => b.price.compareTo(a.price));
    } else {
      // Mới nhất (mặc định)
      _filteredRooms.sort((RoomEntity a, RoomEntity b) => b.id.compareTo(a.id));
    }
  }
}
