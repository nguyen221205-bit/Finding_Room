import '../models/room_model.dart';
import '../../domain/entities/app_enums.dart';

class MockRooms {
  static List<RoomModel> all() {
    return <RoomModel>[
      RoomModel(
        id: 'r1',
        title: 'Sunny Studio Near Downtown',
        price: 4500000,
        address: '12 Nguyễn Trãi, Quận 1',
        area: 28,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=60',
          'https://images.unsplash.com/photo-1449247666642-264389f5f5b1?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Bright studio with big windows, fully furnished and close to bus stops, cafes and supermarkets.',
        amenities: const <String>['Wifi', 'Máy lạnh', 'Giữ xe'],
        isFavorite: false,
        ownerId: 'u_landlord_1',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'Fully furnished',
        landlordName: 'Minh Tran',
        landlordPhone: '+84901234567',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r2',
        title: 'Modern 1BR with Balcony',
        price: 6500000,
        address: '88 Lê Lợi, Quận 1',
        area: 42,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=60',
          'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Spacious 1-bedroom apartment with balcony, good ventilation and a quiet neighborhood.',
        amenities: const <String>['Wifi', 'Giữ xe', 'Nội thất'],
        isFavorite: false,
        ownerId: 'u_landlord_2',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.rented,
        capacity: 3,
        furniture: 'Partly furnished',
        landlordName: 'Linh Nguyen',
        landlordPhone: '+84908886655',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r3',
        title: 'Budget Room for Students',
        price: 2200000,
        address: '5 Phạm Văn Đồng, Bình Thạnh',
        area: 18,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Affordable room with shared kitchen. Perfect for students, near universities and convenience stores.',
        amenities: const <String>['Wifi', 'Giữ xe'],
        isFavorite: false,
        ownerId: 'u_landlord_3',
        status: RoomStatus.pending,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 1,
        furniture: 'Basic furnished',
        landlordName: 'Hai Pham',
        landlordPhone: '+84909990011',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1590086782792-42dd2350140d?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r4',
        title: 'Cozy Room in Shared House',
        price: 3200000,
        address: '31 Võ Văn Tần, Quận 3',
        area: 22,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1501183638710-841dd1904471?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Clean room in a friendly shared house. Shared living room, kitchen, and weekly cleaning service.',
        amenities: const <String>['Wifi', 'Máy giặt', 'Nội thất'],
        isFavorite: false,
        ownerId: 'u_landlord_4',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'Furnished',
        landlordName: 'Trang Le',
        landlordPhone: '+84901239876',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r5',
        title: 'Luxury 2BR Apartment',
        price: 12000000,
        address: '10 Landmark, Bình Thạnh',
        area: 78,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=60',
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'High-floor 2-bedroom apartment with city view, gym and swimming pool access in the building.',
        amenities: const <String>['Wifi', 'Nội thất', 'Giữ xe', 'Máy giặt'],
        isFavorite: false,
        ownerId: 'u_landlord_5',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.rented,
        capacity: 4,
        furniture: 'Luxury furnished',
        landlordName: 'Duc Hoang',
        landlordPhone: '+84901200022',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r6',
        title: 'Small Room Near Metro',
        price: 2800000,
        address: '50 Trần Hưng Đạo, Quận 5',
        area: 16,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Compact room suitable for a single person. Great access to the upcoming metro line and markets.',
        amenities: const <String>['Wifi', 'Máy lạnh'],
        isFavorite: false,
        ownerId: 'u_landlord_6',
        status: RoomStatus.rejected,
        rejectionReason: 'Missing room photos and incomplete address details.',
        availability: RoomAvailability.available,
        capacity: 1,
        furniture: 'Basic',
        landlordName: 'Anh Vu',
        landlordPhone: '+84901111222',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r7',
        title: 'Pet-Friendly Apartment',
        price: 5200000,
        address: '77 Phan Xích Long, Phú Nhuận',
        area: 40,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Comfortable apartment in a lively area with many restaurants. Pets are welcome with a small deposit.',
        amenities: const <String>['Wifi', 'Máy giặt', 'Bếp'],
        isFavorite: false,
        ownerId: 'u_landlord_7',
        status: RoomStatus.pending,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'Furnished',
        landlordName: 'Khanh Do',
        landlordPhone: '+84903334455',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r8',
        title: 'New Room with Security',
        price: 3900000,
        address: '9 Điện Biên Phủ, Quận 10',
        area: 26,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Newly built room with 24/7 security and key-card access. Quiet building with friendly staff.',
        amenities: const <String>['Wifi', 'Giữ xe', 'Nội thất'],
        isFavorite: false,
        ownerId: 'u_landlord_8',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'New furnished',
        landlordName: 'Thao Bui',
        landlordPhone: '+84905556677',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1554151228-14d9def656e4?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r9',
        title: 'Spacious Room with Parking',
        price: 4800000,
        address: '120 Cộng Hòa, Tân Bình',
        area: 35,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1501183638710-841dd1904471?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Large room with private bathroom and free motorbike parking. Close to the airport and offices.',
        amenities: const <String>['Giữ xe', 'Wifi', 'Máy lạnh'],
        isFavorite: false,
        ownerId: 'u_landlord_9',
        status: RoomStatus.rejected,
        rejectionReason:
            'Price information does not match the submitted listing.',
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'Furnished',
        landlordName: 'Son Le',
        landlordPhone: '+84907778899',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=200&q=60',
      ),
      RoomModel(
        id: 'r10',
        title: 'Quiet Studio with Green View',
        price: 5600000,
        address: '15 Thảo Điền, Quận 2',
        area: 38,
        imageUrls: const <String>[
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=60',
          'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=1200&q=60',
        ],
        description:
            'Peaceful studio surrounded by greenery. Perfect for remote work with good natural light.',
        amenities: const <String>['Wifi', 'Máy lạnh', 'Bếp'],
        isFavorite: false,
        ownerId: 'u_landlord_10',
        status: RoomStatus.approved,
        rejectionReason: null,
        availability: RoomAvailability.available,
        capacity: 2,
        furniture: 'Furnished',
        landlordName: 'Nhi Vo',
        landlordPhone: '+84901231231',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
      ),
    ];
  }
}
