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
import '../../widgets/section_header.dart';

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
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _capacityCtrl = TextEditingController(text: '2');
  final TextEditingController _furnitureCtrl = TextEditingController(
    text: 'Furnished',
  );
  final Set<String> _amenities = <String>{'Wifi'};
  final List<String> _imagePaths = <String>[];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes to mark form dirty
    for (final ctrl in <TextEditingController>[
      _titleCtrl,
      _priceCtrl,
      _addressCtrl,
      _areaCtrl,
      _descriptionCtrl,
      _capacityCtrl,
      _furnitureCtrl,
    ]) {
      ctrl.addListener(markFormDirty);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    _furnitureCtrl.dispose();
    super.dispose();
  }

  String? _numberRequired(String? value, String label) {
    return Validators.positiveNumber(value, label: label);
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
      AppSnackbar.error(context, 'Could not open image picker.');
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
      context.read<RoomProvider>().addRoom(
            ownerId: auth.userId,
            landlordName: auth.username,
            landlordPhone: '+84000000000',
            landlordAvatarUrl:
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=60',
            title: _titleCtrl.text,
            price: int.parse(_priceCtrl.text.trim()),
            address: _addressCtrl.text,
            area: double.parse(_areaCtrl.text.trim()),
            description: _descriptionCtrl.text,
            amenities: _amenities.toList(),
            capacity: int.parse(_capacityCtrl.text.trim()),
            furniture: _furnitureCtrl.text,
            imageUrls: _imagePaths,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackbar.error(context, 'Could not submit room. Try again.');
      return;
    }

    if (!mounted) return;
    markFormClean(); // Allow navigation after successful submit
    AppSnackbar.success(context, 'Room submitted for approval.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool canAccess =
        auth.hasRole(UserRole.landlord) &&
        context.watch<RoleProvider>().currentMode == UserRole.landlord;

    if (!canAccess) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Only landlords can add rooms',
            message: 'Switch to landlord mode to submit a room listing.',
          ),
        ),
      );
    }

    return buildUnsavedFormGuard(
      child: DismissKeyboard(
        child: Scaffold(
          appBar: AppBar(title: const Text('Add Room')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    AppTextField(
                      controller: _titleCtrl,
                      label: 'Title',
                      validator: (String? value) =>
                          Validators.minLength(value, label: 'Title'),
                    ),
                    AppSpacing.vMd,
                    AppTextField(
                      controller: _priceCtrl,
                      label: 'Price',
                      keyboardType: TextInputType.number,
                      validator: (String? value) =>
                          _numberRequired(value, 'Price'),
                    ),
                    AppSpacing.vMd,
                    AppTextField(
                      controller: _addressCtrl,
                      label: 'Address',
                      validator: (String? value) =>
                          Validators.minLength(value, label: 'Address'),
                    ),
                    AppSpacing.vMd,
                    AppTextField(
                      controller: _areaCtrl,
                      label: 'Area (m2)',
                      keyboardType: TextInputType.number,
                      validator: (String? value) =>
                          _numberRequired(value, 'Area'),
                    ),
                    AppSpacing.vMd,
                    AppTextField(
                      controller: _capacityCtrl,
                      label: 'Capacity',
                      keyboardType: TextInputType.number,
                      validator: (String? value) =>
                          _numberRequired(value, 'Capacity'),
                    ),
                    AppSpacing.vMd,
                    AppTextField(
                      controller: _furnitureCtrl,
                      label: 'Furniture',
                      validator: (String? value) =>
                          Validators.requiredField(value, label: 'Furniture'),
                    ),
                    AppSpacing.vMd,
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 4,
                      validator: (String? value) => Validators.minLength(
                        value,
                        label: 'Description',
                        minLength: 10,
                      ),
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    AppSpacing.vMd,
                    _RoomImagePicker(
                      imagePaths: _imagePaths,
                      onPick: _pickRoomImage,
                      onRemove: _removeRoomImage,
                    ),
                    AppSpacing.vMd,
                    const SectionHeader(title: 'Amenities'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: AppConstants.amenities.map((String amenity) {
                        return FilterChip(
                          label: Text(amenity),
                          selected: _amenities.contains(amenity),
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
                    AppSpacing.vXl,
                    PrimaryButton(
                      label: 'Submit Room',
                      icon: Icons.check_circle_outline,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : () => _submit(auth),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                'Room images',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(imagePaths.isEmpty ? 'Select Image' : 'Add Image'),
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
                  child: const Text(
                    'No image selected. Default image will be used.',
                    textAlign: TextAlign.center,
                  ),
                )
              : SizedBox(
                  key: const ValueKey<String>('has_images'),
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final String path = imagePaths[index];
                      return Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: AppRadius.mediumAll,
                            child: SizedBox(
                              width: 150,
                              height: 120,
                              child: AppImage(imagePath: path),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: IconButton.filledTonal(
                              onPressed: () => onRemove(path),
                              icon: const Icon(Icons.close, size: 18),
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
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
