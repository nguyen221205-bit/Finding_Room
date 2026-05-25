import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/local_image_service.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/landlord_request_entity.dart';
import '../../mixins/unsaved_form_mixin.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dismiss_keyboard.dart';

class LandlordVerificationScreen extends StatefulWidget {
  const LandlordVerificationScreen({super.key});

  @override
  State<LandlordVerificationScreen> createState() =>
      _LandlordVerificationScreenState();
}

class _LandlordVerificationScreenState
    extends State<LandlordVerificationScreen>
    with UnsavedFormMixin<LandlordVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Multi-step states:
  // -1: Select Verification Type
  // 0: Upload CCCD (front, back, selfie)
  // 1: Fill details form
  // 2: Review & Confirm
  int _currentStep = -1;
  String _verificationType = 'personal'; // 'personal' or 'business'
  
  // CCCD image paths
  String _frontIdImagePath = '';
  String _backIdImagePath = '';
  String _selfieWithIdImagePath = '';

  // Controllers for details
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _identityNumberCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _taxCodeCtrl;
  late final TextEditingController _purposeCtrl;
  
  bool _isRequirementsExpanded = true;
  bool _isSubmitting = false;
  bool _isSubmittedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    final AuthProvider auth = context.read<AuthProvider>();
    final LandlordRequestEntity? request = context
        .read<LandlordRequestProvider>()
        .getUserRequest(auth.userId);

    _fullNameCtrl = TextEditingController(text: request?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: request?.phoneNumber ?? '');
    _identityNumberCtrl = TextEditingController(
      text: request?.identityNumber ?? '',
    );
    _addressCtrl = TextEditingController(text: request?.currentAddress ?? '');
    _taxCodeCtrl = TextEditingController(text: request?.taxCode ?? '');
    _purposeCtrl = TextEditingController(text: request?.purpose ?? '');
    
    _frontIdImagePath = request?.frontIdImage ?? '';
    _backIdImagePath = request?.backIdImage ?? '';
    _selfieWithIdImagePath = request?.selfieWithIdImage ?? '';
    _verificationType = request?.verificationType ?? 'personal';

    // Register controllers
    for (final ctrl in <TextEditingController>[
      _fullNameCtrl,
      _phoneCtrl,
      _identityNumberCtrl,
      _addressCtrl,
      _taxCodeCtrl,
      _purposeCtrl,
    ]) {
      ctrl.addListener(markFormDirty);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _identityNumberCtrl.dispose();
    _addressCtrl.dispose();
    _taxCodeCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageIndex) async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh bằng máy ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _processPick(imageIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _processPick(imageIndex, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPick(int imageIndex, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      final String savedPath = await LocalImageService.copyToAppStorage(
        sourcePath: image.path,
        folderName: 'identity_images',
      );

      setState(() {
        if (imageIndex == 1) {
          _frontIdImagePath = savedPath;
        } else if (imageIndex == 2) {
          _backIdImagePath = savedPath;
        } else if (imageIndex == 3) {
          _selfieWithIdImagePath = savedPath;
        }
      });
      markFormDirty();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Lỗi tải ảnh: $e');
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final LandlordRequestProvider provider = context.read<LandlordRequestProvider>();

    setState(() => _isSubmitting = true);
    bool submitted = false;

    try {
      submitted = await provider.submitRequest(
        userId: auth.userId,
        fullName: _fullNameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        identityNumber: _identityNumberCtrl.text,
        currentAddress: _addressCtrl.text,
        identityImageUrl: _frontIdImagePath, // compatibility
        requestMessage: _purposeCtrl.text,   // compatibility
        verificationType: _verificationType,
        frontIdImage: _frontIdImagePath,
        backIdImage: _backIdImagePath,
        selfieWithIdImage: _selfieWithIdImagePath,
        taxCode: _taxCodeCtrl.text,
        purpose: _purposeCtrl.text,
      );
    } catch (e) {
      submitted = false;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;

    if (submitted) {
      setState(() {
        _isSubmittedSuccessfully = true;
      });
    } else {
      AppSnackbar.error(
        context,
        provider.error ?? 'Đã xảy ra lỗi khi gửi yêu cầu xác minh.',
      );
    }
  }

  void _showBusinessUnderDevelopment() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.blue),
            SizedBox(width: 8),
            Text('Đang phát triển'),
          ],
        ),
        content: const Text(
          'Tính năng "Xác thực doanh nghiệp" đang được hoàn thiện. Vui lòng chọn "Xác thực cá nhân" để tiếp tục quy trình đăng ký chủ nhà trọ.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  // --- Step INDICATORS ---
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: <Widget>[
          _buildStepNode(0, 'Giấy tờ'),
          _buildStepConnector(0),
          _buildStepNode(1, 'Thông tin'),
          _buildStepConnector(1),
          _buildStepNode(2, 'Xác nhận'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label) {
    final theme = Theme.of(context);
    final bool isCompleted = _currentStep > index;
    final bool isActive = _currentStep == index;

    return Expanded(
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: isCompleted
                ? Colors.green
                : isActive
                    ? theme.colorScheme.primary
                    : Colors.grey[300],
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? theme.colorScheme.primary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final bool isCompleted = _currentStep > stepIndex;
    return Container(
      width: 30,
      height: 2,
      color: isCompleted ? Colors.green : Colors.grey[300],
    );
  }

  // --- Image Requirements Expandable Tile ---
  Widget _buildRequirementsSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isRequirementsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isRequirementsExpanded = expanded;
            });
          },
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            'Yêu cầu hình ảnh xác thực',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequirementItem('1. Thông tin rõ ràng, không bị che khuất, rách, tẩy xóa'),
                  const SizedBox(height: 6),
                  _buildRequirementItem('2. Đảm bảo thông tin trùng khớp với CCCD'),
                  const SizedBox(height: 6),
                  _buildRequirementItem('3. Đảm bảo hình ảnh rõ nét và không bị mờ'),
                  const SizedBox(height: 6),
                  _buildRequirementItem('4. Đảm bảo dấu đỏ trên CCCD của bạn rõ ràng'),
                  const SizedBox(height: 6),
                  _buildRequirementItem('5. Đảm bảo CCCD của bạn còn thời hạn'),
                  const SizedBox(height: 6),
                  _buildRequirementItem('6. Cần cung cấp ảnh chụp bản thân cầm CCCD'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }

  // --- SCREEN BUILDS BY STEP ---

  // TYPE SELECTION SCREEN (-1)
  Widget _buildTypeSelectionView() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Đăng ký chủ nhà trọ',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn loại hình xác minh phù hợp để bắt đầu đăng tin và quản lý phòng cho thuê',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        
        // Option 1: Personal
        _buildSelectionCard(
          title: 'Xác thực cá nhân',
          subtitle: 'Dành cho cá nhân cho thuê phòng độc lập',
          icon: Icons.person_outline,
          onTap: () {
            setState(() {
              _verificationType = 'personal';
              _currentStep = 0;
            });
          },
        ),
        const SizedBox(height: 16),

        // Option 2: Business
        _buildSelectionCard(
          title: 'Xác thực doanh nghiệp',
          subtitle: 'Dành cho công ty, tổ chức hoặc hộ kinh doanh cá thể',
          icon: Icons.business_outlined,
          onTap: _showBusinessUnderDevelopment,
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // STEP 0: CCCD
  Widget _buildStep0CCCDView() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 20),
        _buildRequirementsSection(),
        const SizedBox(height: 20),
        
        Text(
          'Tải lên hình ảnh giấy tờ',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Front Side Card
        _buildImageUploadCard(
          label: 'Mặt trước CCCD',
          imagePath: _frontIdImagePath,
          onPick: () => _pickImage(1),
          onClear: () => setState(() => _frontIdImagePath = ''),
        ),
        const SizedBox(height: 16),

        // Back Side Card
        _buildImageUploadCard(
          label: 'Mặt sau CCCD',
          imagePath: _backIdImagePath,
          onPick: () => _pickImage(2),
          onClear: () => setState(() => _backIdImagePath = ''),
        ),
        const SizedBox(height: 16),

        // Selfie Card
        _buildImageUploadCard(
          label: 'Ảnh chân dung cầm CCCD',
          imagePath: _selfieWithIdImagePath,
          onPick: () => _pickImage(3),
          onClear: () => setState(() => _selfieWithIdImagePath = ''),
        ),
        const SizedBox(height: 32),

        // Bottom Controls
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = -1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (_frontIdImagePath.isNotEmpty &&
                        _backIdImagePath.isNotEmpty &&
                        _selfieWithIdImagePath.isNotEmpty)
                    ? () => setState(() => _currentStep = 1)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tiếp theo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String label,
    required String imagePath,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final bool hasImage = imagePath.isNotEmpty;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (!hasImage)
              InkWell(
                onTap: onPick,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Nhấp để chụp hoặc tải lên', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            if (hasImage) ...[
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                        onPressed: onPick,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white),
                        onPressed: onClear,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 1: FORM DETAILS
  Widget _buildStep1FormView() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 20),
          
          Text(
            'Nhập thông tin cá nhân',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _fullNameCtrl,
            label: 'Họ tên đầy đủ',
            prefixIcon: const Icon(Icons.person_outline),
            validator: (String? value) =>
                Validators.requiredField(value, label: 'Họ tên'),
          ),
          AppSpacing.vMd,
          
          AppTextField(
            controller: _identityNumberCtrl,
            label: 'Số CCCD',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.badge_outlined),
            validator: Validators.identityNumber,
          ),
          AppSpacing.vMd,

          AppTextField(
            controller: _phoneCtrl,
            label: 'Số điện thoại',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: Validators.phone,
          ),
          AppSpacing.vMd,

          AppTextField(
            controller: _taxCodeCtrl,
            label: 'Mã số thuế (nếu có)',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
          AppSpacing.vMd,

          AppTextField(
            controller: _addressCtrl,
            label: 'Địa chỉ thường trú',
            prefixIcon: const Icon(Icons.location_on_outlined),
            validator: (String? value) =>
                Validators.minLength(value, label: 'Địa chỉ', minLength: 5),
          ),
          AppSpacing.vMd,

          TextFormField(
            controller: _purposeCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            validator: (String? value) => Validators.minLength(
              value,
              label: 'Mục đích đăng ký',
              minLength: 10,
            ),
            decoration: const InputDecoration(
              labelText: 'Mục đích đăng ký',
              prefixIcon: Icon(Icons.info_outline),
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Controls
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _currentStep = 2);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tiếp theo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 2: CONFIRMATION
  Widget _buildStep2ConfirmationView() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 20),

        Text(
          'Xác nhận thông tin xác thực',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Section 1: Personal Info
        _buildReviewSection(
          title: 'Thông tin cá nhân',
          items: {
            'Họ và tên': _fullNameCtrl.text,
            'Số CCCD': _identityNumberCtrl.text,
            'Mã số thuế': _taxCodeCtrl.text.isEmpty ? 'Không cung cấp' : _taxCodeCtrl.text,
          },
        ),
        const SizedBox(height: 16),

        // Section 2: Contact Info
        _buildReviewSection(
          title: 'Thông tin liên hệ',
          items: {
            'Số điện thoại': _phoneCtrl.text,
            'Địa chỉ': _addressCtrl.text,
            'Mục đích đăng ký': _purposeCtrl.text,
          },
        ),
        const SizedBox(height: 16),

        // Section 3: Identity Photos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hình ảnh tài liệu',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildReviewThumbnail('Mặt trước', _frontIdImagePath)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildReviewThumbnail('Mặt sau', _backIdImagePath)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildReviewThumbnail('Selfie', _selfieWithIdImagePath)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Bottom Controls
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Xác nhận & Gửi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSection({required String title, required Map<String, String> items}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          ...items.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReviewThumbnail(String label, String imagePath) {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // --- SUCCESS PENDING REVIEW SCREEN ---
  Widget _buildPendingReviewScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orangeAccent,
                child: Icon(
                  Icons.hourglass_empty_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Yêu cầu đang được xử lý',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cảm ơn bạn đã gửi thông tin xác minh. Ban quản trị hệ thống sẽ xem xét hồ sơ của bạn và phê duyệt trong vòng 24 giờ làm việc.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  markFormClean();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Quay lại trang cá nhân',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmittedSuccessfully) {
      return _buildPendingReviewScreen();
    }

    final String appBarTitle = _currentStep == -1
        ? 'Đăng ký chủ nhà trọ'
        : _currentStep == 0
            ? 'Xác minh CCCD'
            : _currentStep == 1
                ? 'Thông tin cá nhân'
                : 'Xác nhận thông tin';

    return buildUnsavedFormGuard(
      child: DismissKeyboard(
        child: Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_currentStep == -1) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    if (_currentStep == 0) {
                      _currentStep = -1;
                    } else if (_currentStep == 1) {
                      _currentStep = 0;
                    } else {
                      _currentStep = 1;
                    }
                  });
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == -1
                    ? _buildTypeSelectionView()
                    : _currentStep == 0
                        ? _buildStep0CCCDView()
                        : _currentStep == 1
                            ? _buildStep1FormView()
                            : _buildStep2ConfirmationView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
