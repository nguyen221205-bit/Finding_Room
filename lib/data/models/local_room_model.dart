import '../../domain/entities/app_enums.dart';
import '../../domain/entities/room_entity.dart';

class LocalRoomModel {
  final RoomEntity room;

  const LocalRoomModel(this.room);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': room.id,
      'title': room.title,
      'price': room.price,
      'address': room.address,
      'area': room.area,
      'imageUrls': room.imageUrls,
      'description': room.description,
      'amenities': room.amenities,
      'isFavorite': room.isFavorite,
      'ownerId': room.ownerId,
      'status': room.status.name,
      'rejectionReason': room.rejectionReason,
      'availability': room.availability.name,
      'capacity': room.capacity,
      'furniture': room.furniture,
      'landlordName': room.landlordName,
      'landlordPhone': room.landlordPhone,
      'landlordAvatarUrl': room.landlordAvatarUrl,
    };
  }

  static RoomEntity fromMap(Map<dynamic, dynamic> map) {
    return RoomEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      price: map['price'] as int? ?? 0,
      address: map['address'] as String? ?? '',
      area: (map['area'] as num?)?.toDouble() ?? 0,
      imageUrls: _stringList(map['imageUrls']),
      description: map['description'] as String? ?? '',
      amenities: _stringList(map['amenities']),
      isFavorite: map['isFavorite'] as bool? ?? false,
      ownerId: map['ownerId'] as String? ?? '',
      status: _roomStatusFromName(map['status'] as String?),
      rejectionReason: map['rejectionReason'] as String?,
      availability: _availabilityFromName(map['availability'] as String?),
      capacity: map['capacity'] as int? ?? 1,
      furniture: map['furniture'] as String? ?? 'Unfurnished',
      landlordName: map['landlordName'] as String? ?? 'Landlord',
      landlordPhone: map['landlordPhone'] as String? ?? '',
      landlordAvatarUrl: map['landlordAvatarUrl'] as String? ?? '',
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }

  static RoomStatus _roomStatusFromName(String? name) {
    return RoomStatus.values.firstWhere(
      (RoomStatus status) => status.name == name,
      orElse: () => RoomStatus.pending,
    );
  }

  static RoomAvailability _availabilityFromName(String? name) {
    return RoomAvailability.values.firstWhere(
      (RoomAvailability a) => a.name == name,
      orElse: () => RoomAvailability.available,
    );
  }
}
