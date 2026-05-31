import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/landlord_request_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/status_badge.dart';
import 'request_detail_screen.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  String? _processingRequestId;

  Future<String?> _askRejectReason(BuildContext context) {
    return AppDialogs.showRejectionDialog(
      context: context,
      title: 'Reject request',
      label: 'Reason',
      hint: 'Explain why this verification was rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool canAccess = auth.hasRole(UserRole.admin);
    if (!canAccess) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Access Denied',
            message: 'Only admins can view requests in admin mode.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Requests')),
      body: Consumer<LandlordRequestProvider>(
        builder: (BuildContext context, LandlordRequestProvider provider, _) {
          if (provider.isLoading && !provider.hasLoaded) {
            return Padding(
              padding: AppSpacing.paddingAllLg,
              child: const LoadingPlaceholderList(itemCount: 3),
            );
          }

          if (provider.requests.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No landlord requests',
              message: 'New landlord requests will appear here.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingAllLg,
            itemCount: provider.requests.length,
            separatorBuilder: (BuildContext context, int index) =>
                AppSpacing.vMd,
            itemBuilder: (BuildContext context, int index) {
              final LandlordRequestEntity request = provider.requests[index];
              final bool isProcessing = _processingRequestId == request.id;

              final StatusBadge badge = switch (request.status) {
                LandlordRequestStatus.pending => const StatusBadge.pending(),
                LandlordRequestStatus.approved => const StatusBadge.approved(),
                LandlordRequestStatus.rejected => const StatusBadge.rejected(),
              };

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RequestDetailScreen(requestId: request.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: AppSpacing.paddingAllLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Mã yêu cầu: ${request.verificationCode}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            badge,
                          ],
                        ),
                        AppSpacing.vMd,
                        _IdentityPreview(imagePath: request.identityImageUrl),
                        AppSpacing.vMd,
                        _InfoLine(label: 'Full name', value: request.fullName),
                        FutureBuilder<UserEntity?>(
                          future: context.read<AuthProvider>().getUserById(
                            request.userId,
                          ),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            if (user == null || user.userCode.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _InfoLine(
                              label: 'Mã người dùng',
                              value: user.userCode,
                            );
                          },
                        ),
                        _InfoLine(label: 'Phone', value: request.phoneNumber),
                        _InfoLine(
                          label: 'Identity number',
                          value: request.identityNumber,
                        ),
                        _InfoLine(
                          label: 'Address',
                          value: request.currentAddress,
                          maxLines: 2,
                        ),
                        _InfoLine(
                          label: 'Message',
                          value: request.requestMessage,
                          maxLines: 3,
                        ),
                        if (request.rejectionReason != null &&
                            request.rejectionReason!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            'Reason: ${request.rejectionReason!}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Divider(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Chạm để xem chi tiết đầy đủ & duyệt ảnh',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (request.status ==
                            LandlordRequestStatus.pending) ...<Widget>[
                          AppSpacing.vMd,
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final bool confirm =
                                              await AppDialogs.confirmApprove(
                                                context,
                                                "landlord request for ${request.fullName}",
                                              );
                                          if (!confirm || !mounted) return;

                                          setState(
                                            () => _processingRequestId =
                                                request.id,
                                          );
                                          final bool ok = await provider
                                              .approveRequest(request.id);
                                          if (mounted) {
                                            setState(
                                              () => _processingRequestId = null,
                                            );
                                            AppSnackbar.showWithMessenger(
                                              messenger,
                                              ok
                                                  ? 'Request approved.'
                                                  : 'Could not approve request.',
                                            );
                                          }
                                        },
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Approve'),
                                ),
                              ),
                              AppSpacing.hMd,
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final String? reason =
                                              await _askRejectReason(context);
                                          if (reason == null) return;

                                          if (!mounted) return;
                                          setState(
                                            () => _processingRequestId =
                                                request.id,
                                          );
                                          final bool ok = await provider
                                              .rejectRequest(
                                                requestId: request.id,
                                                reason: reason,
                                              );
                                          if (mounted) {
                                            setState(
                                              () => _processingRequestId = null,
                                            );
                                            AppSnackbar.showWithMessenger(
                                              messenger,
                                              ok
                                                  ? 'Request rejected.'
                                                  : 'Could not reject request.',
                                            );
                                          }
                                        },
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IdentityPreview extends StatelessWidget {
  final String imagePath;

  const _IdentityPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: AppImage(imagePath: imagePath),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InfoLine({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
