import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/landlord_request_entity.dart';
import '../../providers/landlord_request_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/status_badge.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isProcessing = false;

  void _showFullscreenImage(BuildContext context, String title, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imagePath,
                  child: AppImage(
                    imagePath: imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _askRejectReason(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Từ chối yêu cầu'),
            ],
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Lý do từ chối',
              hintText: 'Nhập lý do chi tiết từ chối yêu cầu này...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(reasonController.text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Từ chối'),
            ),
          ],
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa cung cấp',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard({
    required BuildContext context,
    required String title,
    required String imagePath,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _showFullscreenImage(context, title, imagePath),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: imagePath,
                  child: AppImage(imagePath: imagePath),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 14,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LandlordRequestProvider>();
    final LandlordRequestEntity? request = provider.requests
        .where((r) => r.id == widget.requestId)
        .firstOrNull;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết xác thực')),
        body: const Center(
          child: Text('Không tìm thấy yêu cầu xác thực.'),
        ),
      );
    }

    final StatusBadge badge = switch (request.status) {
      LandlordRequestStatus.pending => const StatusBadge.pending(),
      LandlordRequestStatus.approved => const StatusBadge.approved(),
      LandlordRequestStatus.rejected => const StatusBadge.rejected(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm duyệt chủ nhà'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner at the top
            Container(
              color: switch (request.status) {
                LandlordRequestStatus.pending => Colors.orange.shade50,
                LandlordRequestStatus.approved => Colors.green.shade50,
                LandlordRequestStatus.rejected => Colors.red.shade50,
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Trạng thái hồ sơ: ',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            badge,
                          ],
                        ),
                        if (request.status == LandlordRequestStatus.rejected &&
                            request.rejectionReason != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lý do từ chối: ${request.rejectionReason}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: AppSpacing.paddingAllLg,
                children: [
                  // Section 1: Verification Images
                  _buildInfoSection(
                    context: context,
                    title: 'Giấy tờ xác minh (CCCD / CMND)',
                    icon: Icons.photo_library_outlined,
                    children: [
                      const Text(
                        'Nhấp vào ảnh để mở xem toàn màn hình và phóng to kiểm tra chi tiết.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildImagePreviewCard(
                            context: context,
                            title: 'Mặt trước',
                            imagePath: request.frontIdImage.isNotEmpty
                                ? request.frontIdImage
                                : request.identityImageUrl,
                          ),
                          AppSpacing.hMd,
                          _buildImagePreviewCard(
                            context: context,
                            title: 'Mặt sau',
                            imagePath: request.backIdImage,
                          ),
                          AppSpacing.hMd,
                          _buildImagePreviewCard(
                            context: context,
                            title: 'Ảnh selfie',
                            imagePath: request.selfieWithIdImage,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Personal Information
                  _buildInfoSection(
                    context: context,
                    title: 'Thông tin cá nhân',
                    icon: Icons.person_outline,
                    children: [
                      _buildInfoItem(context, 'Họ và tên', request.fullName),
                      _buildInfoItem(context, 'Số CCCD', request.identityNumber),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Contact Information
                  _buildInfoSection(
                    context: context,
                    title: 'Thông tin liên hệ',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _buildInfoItem(context, 'Số điện thoại', request.phoneNumber),
                      _buildInfoItem(context, 'Địa chỉ hiện tại', request.currentAddress, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Authentic Details
                  _buildInfoSection(
                    context: context,
                    title: 'Chi tiết xác thực thêm',
                    icon: Icons.verified_user_outlined,
                    children: [
                      _buildInfoItem(
                        context,
                        'Mã số thuế',
                        request.taxCode != null && request.taxCode!.isNotEmpty ? request.taxCode! : 'Chưa đăng ký MST',
                      ),
                      _buildInfoItem(
                        context,
                        'Mục đích',
                        request.purpose.isNotEmpty ? request.purpose : request.requestMessage,
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Section 5: Bottom Action Buttons if pending
            if (request.status == LandlordRequestStatus.pending)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final String? reason = await _askRejectReason(context);
                                if (reason == null || reason.trim().isEmpty) return;

                                setState(() => _isProcessing = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final bool ok = provider.rejectRequest(
                                  requestId: request.id,
                                  reason: reason,
                                );
                                setState(() => _isProcessing = false);

                                if (ok) {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Đã từ chối yêu cầu xác thực.',
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Có lỗi xảy ra khi thực hiện từ chối.',
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Từ chối',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final bool confirm = await AppDialogs.confirmApprove(
                                  context,
                                  "Yêu cầu làm chủ nhà của ${request.fullName}",
                                );
                                if (!confirm) return;

                                setState(() => _isProcessing = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final bool ok = provider.approveRequest(request.id);
                                setState(() => _isProcessing = false);

                                if (ok) {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Đã phê duyệt yêu cầu xác thực.',
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Có lỗi xảy ra khi phê duyệt.',
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Phê duyệt',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
