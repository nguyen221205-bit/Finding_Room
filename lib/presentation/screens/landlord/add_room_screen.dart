import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/local_image_service.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/app_enums.dart';
import '../../mixins/unsaved_form_mixin.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/app_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen>
    with UnsavedFormMixin<AddRoomScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _detailedAddressCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _usableAreaCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _capacityCtrl = TextEditingController(text: '2');
  final TextEditingController _furnitureCtrl = TextEditingController(
    text: 'Đầy đủ nội thất',
  );
  final TextEditingController _latitudeCtrl = TextEditingController(
    text: '10.762622',
  );
  final TextEditingController _longitudeCtrl = TextEditingController(
    text: '106.660172',
  );

  String _selectedDistrict = 'Quận 10';
  RoomAvailability _availability = RoomAvailability.available;
  final Set<String> _amenities = <String>{'Wifi'};
  final List<String> _imagePaths = <String>[];
  bool _isSubmitting = false;

  static const List<String> _districts = <String>[
    'Quận 1',
    'Quận 3',
    'Quận 4',
    'Quận 5',
    'Quận 6',
    'Quận 7',
    'Quận 8',
    'Quận 10',
    'Quận 11',
    'Quận 12',
    'Quận Bình Thạnh',
    'Quận Gò Vấp',
    'Quận Phú Nhuận',
    'Quận Tân Bình',
    'Quận Tân Phú',
    'Quận Bình Tân',
    'TP. Thủ Đức',
    'Huyện Bình Chánh',
    'Huyện Nhà Bè',
    'Huyện Hóc Môn',
    'Huyện Củ Chi',
    'Huyện Cần Giờ',
  ];

  @override
  void initState() {
    super.initState();
    // Listen for changes to mark form dirty
    for (final ctrl in <TextEditingController>[
      _titleCtrl,
      _priceCtrl,
      _detailedAddressCtrl,
      _areaCtrl,
      _usableAreaCtrl,
      _lengthCtrl,
      _widthCtrl,
      _descriptionCtrl,
      _capacityCtrl,
      _furnitureCtrl,
      _latitudeCtrl,
      _longitudeCtrl,
    ]) {
      ctrl.addListener(markFormDirty);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _detailedAddressCtrl.dispose();
    _areaCtrl.dispose();
    _usableAreaCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    _furnitureCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  String? _numberRequired(String? value, String label) {
    return Validators.positiveNumber(value, label: label);
  }

  String? _optionalNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null) return '$label phải là số hợp lệ';
    if (parsed <= 0) return '$label phải lớn hơn 0';
    return null;
  }

  Future<void> _pickRoomImage() async {
    late final XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Không thể mở thư viện ảnh.');
      return;
    }
    if (image == null || !mounted) return;

    final String savedPath = await LocalImageService.copyToAppStorage(
      sourcePath: image.path,
      folderName: 'room_images',
    );
    if (!mounted) return;

    setState(() => _imagePaths.add(savedPath));
    markFormDirty();
  }

  void _removeRoomImage(String path) {
    setState(() => _imagePaths.remove(path));
    markFormDirty();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final String combinedAddress =
          '${_detailedAddressCtrl.text.trim()}, $_selectedDistrict, TP. Hồ Chí Minh';
      final double? usableArea = _usableAreaCtrl.text.isNotEmpty
          ? double.tryParse(_usableAreaCtrl.text.trim())
          : null;
      final double? length = _lengthCtrl.text.isNotEmpty
          ? double.tryParse(_lengthCtrl.text.trim())
          : null;
      final double? width = _widthCtrl.text.isNotEmpty
          ? double.tryParse(_widthCtrl.text.trim())
          : null;
      final double? latitude = _latitudeCtrl.text.isNotEmpty
          ? double.tryParse(_latitudeCtrl.text.trim())
          : null;
      final double? longitude = _longitudeCtrl.text.isNotEmpty
          ? double.tryParse(_longitudeCtrl.text.trim())
          : null;

      final provider = context.read<RoomProvider>();
      final bool ok = await provider.addRoom(
        ownerId: auth.userId,
        landlordName: auth.username,
        landlordPhone: '+84000000000',
        landlordAvatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=60',
        title: _titleCtrl.text.trim(),
        price: int.parse(_priceCtrl.text.trim()),
        address: combinedAddress,
        area: double.parse(_areaCtrl.text.trim()),
        description: _descriptionCtrl.text.trim(),
        amenities: _amenities.toList(),
        capacity: int.parse(_capacityCtrl.text.trim()),
        furniture: _furnitureCtrl.text.trim(),
        imageUrls: _imagePaths,
        usableArea: usableArea,
        length: length,
        width: width,
        district: _selectedDistrict,
        latitude: latitude,
        longitude: longitude,
        availability: _availability,
      );
      if (!ok) {
        throw Exception('Lỗi lưu trữ phòng trọ vào cơ sở dữ liệu');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackbar.error(context, 'Không thể đăng tin trọ. Vui lòng thử lại.');
      return;
    }

    if (!mounted) return;
    markFormClean(); // Allow navigation after successful submit
    AppSnackbar.success(context, 'Tin đăng đã được gửi để kiểm duyệt.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final bool canAccess =
        auth.hasRole(UserRole.landlord) &&
        context.watch<RoleProvider>().currentMode == UserRole.landlord;

    if (!canAccess) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Chỉ chủ trọ mới có thể đăng tin',
            message: 'Vui lòng chuyển sang chế độ chủ trọ để đăng tin mới.',
          ),
        ),
      );
    }

    return buildUnsavedFormGuard(
      child: DismissKeyboard(
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Đăng phòng trọ mới'),
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // SECTION 1: BASIC INFORMATION
                    _buildFormSection(
                      title: 'Thông tin cơ bản',
                      icon: Icons.info_outline,
                      children: [
                        AppTextField(
                          controller: _titleCtrl,
                          label: 'Tiêu đề tin đăng',
                          validator: (String? value) => Validators.minLength(
                            value,
                            label: 'Tiêu đề',
                            minLength: 8,
                          ),
                        ),
                        AppSpacing.vMd,
                        AppTextField(
                          controller: _priceCtrl,
                          label: 'Giá thuê (đồng/tháng)',
                          keyboardType: TextInputType.number,
                          validator: (String? value) =>
                              _numberRequired(value, 'Giá thuê'),
                        ),
                        AppSpacing.vMd,
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _capacityCtrl,
                                label: 'Sức chứa (người)',
                                keyboardType: TextInputType.number,
                                validator: (String? value) =>
                                    _numberRequired(value, 'Sức chứa'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _furnitureCtrl,
                                label: 'Nội thất',
                                validator: (String? value) =>
                                    Validators.requiredField(
                                      value,
                                      label: 'Nội thất',
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.vLg,

                    // SECTION 2: LOCATION & ADDRESS
                    _buildFormSection(
                      title: 'Địa chỉ & Vị trí',
                      icon: Icons.location_on_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict,
                          decoration: InputDecoration(
                            labelText: 'Quận / Huyện (tại TP.HCM)',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _districts.map((String district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedDistrict = value;
                              });
                              markFormDirty();
                            }
                          },
                        ),
                        AppSpacing.vMd,
                        AppTextField(
                          controller: _detailedAddressCtrl,
                          label: 'Địa chỉ chi tiết (Số nhà, Tên đường, Phường)',
                          validator: (String? value) => Validators.minLength(
                            value,
                            label: 'Địa chỉ',
                            minLength: 5,
                          ),
                        ),
                        AppSpacing.vMd,
                        Text(
                          'Tọa độ bản đồ (Phục vụ hiển thị bản đồ trọ)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _latitudeCtrl,
                                label: 'Vĩ độ (Latitude)',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (String? value) =>
                                    _optionalNumber(value, 'Vĩ độ'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _longitudeCtrl,
                                label: 'Kinh độ (Longitude)',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (String? value) =>
                                    _optionalNumber(value, 'Kinh độ'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.vLg,

                    // SECTION 3: DIMENSIONS & STATUS
                    _buildFormSection(
                      title: 'Kích thước & Trạng thái',
                      icon: Icons.square_foot_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _areaCtrl,
                                label: 'Diện tích đất (m²)',
                                keyboardType: TextInputType.number,
                                validator: (String? value) =>
                                    _numberRequired(value, 'Diện tích đất'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _usableAreaCtrl,
                                label: 'DT sử dụng (m² - tùy chọn)',
                                keyboardType: TextInputType.number,
                                validator: (String? value) =>
                                    _optionalNumber(value, 'Diện tích sử dụng'),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vMd,
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _lengthCtrl,
                                label: 'Chiều dài (m - tùy chọn)',
                                keyboardType: TextInputType.number,
                                validator: (String? value) =>
                                    _optionalNumber(value, 'Chiều dài'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _widthCtrl,
                                label: 'Chiều rộng (m - tùy chọn)',
                                keyboardType: TextInputType.number,
                                validator: (String? value) =>
                                    _optionalNumber(value, 'Chiều rộng'),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vMd,
                        Text(
                          'Trạng thái phòng trống:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Còn trống'),
                              selected:
                                  _availability == RoomAvailability.available,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(
                                    () => _availability =
                                        RoomAvailability.available,
                                  );
                                  markFormDirty();
                                }
                              },
                              selectedColor: Colors.green.shade100,
                              labelStyle: TextStyle(
                                color:
                                    _availability == RoomAvailability.available
                                    ? Colors.green.shade800
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Đã cho thuê'),
                              selected:
                                  _availability == RoomAvailability.rented,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(
                                    () =>
                                        _availability = RoomAvailability.rented,
                                  );
                                  markFormDirty();
                                }
                              },
                              selectedColor: Colors.red.shade100,
                              labelStyle: TextStyle(
                                color: _availability == RoomAvailability.rented
                                    ? Colors.red.shade800
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.vLg,

                    // SECTION 4: DESCRIPTION & AMENITIES
                    _buildFormSection(
                      title: 'Mô tả & Tiện ích',
                      icon: Icons.text_snippet_outlined,
                      children: [
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          validator: (String? value) => Validators.minLength(
                            value,
                            label: 'Mô tả chi tiết',
                            minLength: 10,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                'Mô tả phòng trọ (Ví dụ: thông tin giờ giấc, lối đi...)',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        AppSpacing.vMd,
                        Text(
                          'Tiện ích phòng trọ:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: AppConstants.amenities.map((
                            String amenity,
                          ) {
                            final bool isSelected = _amenities.contains(
                              amenity,
                            );
                            return FilterChip(
                              label: Text(amenity),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade50,
                              checkmarkColor: Colors.blue.shade800,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade800
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _amenities.add(amenity);
                                  } else {
                                    _amenities.remove(amenity);
                                  }
                                });
                                markFormDirty();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    AppSpacing.vLg,

                    // SECTION 5: ROOM IMAGES
                    _buildFormSection(
                      title: 'Hình ảnh phòng trọ',
                      icon: Icons.photo_library_outlined,
                      children: [
                        _RoomImagePicker(
                          imagePaths: _imagePaths,
                          onPick: _pickRoomImage,
                          onRemove: _removeRoomImage,
                        ),
                      ],
                    ),
                    AppSpacing.vXl,

                    PrimaryButton(
                      label: 'Đăng tin phòng trọ',
                      icon: Icons.check_circle_outline,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : () => _submit(auth),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAllLg,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }
}

class _RoomImagePicker extends StatelessWidget {
  final List<String> imagePaths;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  const _RoomImagePicker({
    required this.imagePaths,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Ảnh đã chọn (${imagePaths.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: Text(imagePaths.isEmpty ? 'Chọn ảnh' : 'Thêm ảnh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vSm,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: imagePaths.isEmpty
              ? Container(
                  key: const ValueKey<String>('no_image'),
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerHighlight,
                    borderRadius: AppRadius.mediumAll,
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Chưa chọn ảnh nào. Ảnh mặc định sẽ được hiển thị.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
                    ),
                  ),
                )
              : SizedBox(
                  key: const ValueKey<String>('has_images'),
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final String path = imagePaths[index];
                      final bool isThumbnail = index == 0;
                      return Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: AppRadius.mediumAll,
                            child: SizedBox(
                              width: 150,
                              height: 120,
                              child: AppImage(
                                imagePath: path,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isThumbnail)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ảnh đại diện',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: InkWell(
                              onTap: () => onRemove(path),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
