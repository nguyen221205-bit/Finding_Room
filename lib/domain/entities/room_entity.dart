import 'app_enums.dart';

class RoomEntity {
  final String id;
  final String title;
  final int price; // per month
  final String address;
  final double area; // m²
  final List<String> imageUrls;
  final String description;
  final List<String> amenities;
  final bool isFavorite;
  final String ownerId;
  final RoomStatus status;
  final String? rejectionReason;
  final RoomAvailability availability;

  // Extra details for the detail screen
  final int capacity;
  final String furniture;
  final String landlordName;
  final String landlordPhone;
  final String landlordAvatarUrl;

  const RoomEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.address,
    required this.area,
    required this.imageUrls,
    required this.description,
    required this.amenities,
    required this.isFavorite,
    required this.ownerId,
    required this.status,
    required this.rejectionReason,
    this.availability = RoomAvailability.available,
    required this.capacity,
    required this.furniture,
    required this.landlordName,
    required this.landlordPhone,
    required this.landlordAvatarUrl,
  });

  String get primaryImageUrl {
    if (imageUrls.isEmpty) return '';
    return imageUrls.firstWhere(
      (String imageUrl) => imageUrl.trim().isNotEmpty,
      orElse: () => '',
    );
  }

  RoomEntity copyWith({
    String? id,
    String? title,
    int? price,
    String? address,
    double? area,
    List<String>? imageUrls,
    String? description,
    List<String>? amenities,
    bool? isFavorite,
    String? ownerId,
    RoomStatus? status,
    String? rejectionReason,
    bool clearRejectionReason = false,
    RoomAvailability? availability,
    int? capacity,
    String? furniture,
    String? landlordName,
    String? landlordPhone,
    String? landlordAvatarUrl,
  }) {
    return RoomEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      address: address ?? this.address,
      area: area ?? this.area,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      isFavorite: isFavorite ?? this.isFavorite,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
      availability: availability ?? this.availability,
      capacity: capacity ?? this.capacity,
      furniture: furniture ?? this.furniture,
      landlordName: landlordName ?? this.landlordName,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      landlordAvatarUrl: landlordAvatarUrl ?? this.landlordAvatarUrl,
    );
  }
}
