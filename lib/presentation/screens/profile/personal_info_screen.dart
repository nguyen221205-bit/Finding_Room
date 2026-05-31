import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _zaloController;
  late TextEditingController _bioController;
  String? _avatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final AuthProvider auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _nameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _zaloController = TextEditingController(text: user?.zaloNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarPath = user?.avatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _zaloController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      if (kIsWeb) {
        setState(() {
          _avatarPath = image.path;
        });
        return;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String extension = image.path.contains('.')
          ? image.path.split('.').last
          : 'png';
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String localPath = '${appDir.path}/$fileName';

      final File savedFile = await File(image.path).copy(localPath);
      setState(() {
        _avatarPath = savedFile.path;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Lỗi khi tải ảnh: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final String currentUserId = auth.userId;
    final String trimmedPhone = _phoneController.text.trim();

    if (trimmedPhone.isNotEmpty) {
      // Format validation: starts with 03/05/07/08/09, only digits, exactly 10 digits
      final RegExp phoneRegex = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');
      if (!phoneRegex.hasMatch(trimmedPhone)) {
        AppSnackbar.error(context, 'Số điện thoại không hợp lệ.');
        return;
      }

      // Unique validation
      final bool isUnique = await auth.isPhoneNumberUnique(
        trimmedPhone,
        currentUserId,
      );
      if (!mounted) return;
      if (!isUnique) {
        AppSnackbar.error(
          context,
          'Số điện thoại này đã được sử dụng bởi tài khoản khác.',
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await auth.updateProfile(
        username: _nameController.text.trim(),
        avatarPath: _avatarPath,
        phoneNumber: trimmedPhone,
        zaloNumber: _zaloController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        AppSnackbar.success(context, 'Cập nhật thông tin thành công!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Có lỗi xảy ra: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin'), elevation: 0),
      body: SafeArea(
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppSpacing.paddingAllLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Avatar Section
                      Stack(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: () {
                              final String? path = _avatarPath;
                              if (path == null || path.isEmpty) return null;
                              if (path.startsWith('http')) {
                                return NetworkImage(path) as ImageProvider;
                              }
                              if (path.startsWith('assets/')) {
                                return AssetImage(path) as ImageProvider;
                              }
                              if (!kIsWeb) {
                                return FileImage(File(path)) as ImageProvider;
                              }
                              return null;
                            }(),
                            child: _avatarPath == null || _avatarPath!.isEmpty
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'U',
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Display Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên hiển thị',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          helperText: 'Tên sẽ hiển thị công khai trên ứng dụng',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên hiển thị';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.vMd,

                      // Email (Read-only)
                      TextFormField(
                        initialValue: auth.email.isEmpty
                            ? 'demo@roomfinder.app'
                            : auth.email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                          helperText: 'Không thể thay đổi email đăng nhập',
                        ),
                      ),
                      AppSpacing.vMd,

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final RegExp phoneRegex = RegExp(
                              r'^(03|05|07|08|09)[0-9]{8}$',
                            );
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return 'Số điện thoại không hợp lệ.';
                            }
                          }
                          return null;
                        },
                      ),
                      AppSpacing.vMd,

                      // Zalo Number
                      TextFormField(
                        controller: _zaloController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số Zalo liên hệ',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                          border: OutlineInputBorder(),
                          helperText: 'Để người thuê tiện liên lạc qua Zalo',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final phoneRegex = RegExp(r'^[0-9+]{9,15}$');
                            if (!phoneRegex.hasMatch(value)) {
                              return 'Số điện thoại không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                      AppSpacing.vMd,

                      // Bio / About
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Giới thiệu bản thân',
                          prefixIcon: Icon(Icons.info_outline),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
