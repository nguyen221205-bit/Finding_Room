import '../../domain/entities/app_enums.dart';
import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.title,
    required super.price,
    required super.address,
    required super.area,
    required super.imageUrls,
    required super.description,
    required super.amenities,
    required super.isFavorite,
    required super.ownerId,
    required super.status,
    required super.rejectionReason,
    super.availability = RoomAvailability.available,
    required super.capacity,
    required super.furniture,
    required super.landlordName,
    required super.landlordPhone,
    required super.landlordAvatarUrl,
  });

  RoomModel copyWithModel({
    bool? isFavorite,
    String? ownerId,
    RoomStatus? status,
    String? rejectionReason,
    bool clearRejectionReason = false,
    RoomAvailability? availability,
  }) {
    return RoomModel(
      id: id,
      title: title,
      price: price,
      address: address,
      area: area,
      imageUrls: imageUrls,
      description: description,
      amenities: amenities,
      isFavorite: isFavorite ?? this.isFavorite,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
      availability: availability ?? this.availability,
      capacity: capacity,
      furniture: furniture,
      landlordName: landlordName,
      landlordPhone: landlordPhone,
      landlordAvatarUrl: landlordAvatarUrl,
    );
  }

  static RoomModel fromEntity(RoomEntity e) => RoomModel(
    id: e.id,
    title: e.title,
    price: e.price,
    address: e.address,
    area: e.area,
    imageUrls: e.imageUrls,
    description: e.description,
    amenities: e.amenities,
    isFavorite: e.isFavorite,
    ownerId: e.ownerId,
    status: e.status,
    rejectionReason: e.rejectionReason,
    availability: e.availability,
    capacity: e.capacity,
    furniture: e.furniture,
    landlordName: e.landlordName,
    landlordPhone: e.landlordPhone,
    landlordAvatarUrl: e.landlordAvatarUrl,
  );
}
