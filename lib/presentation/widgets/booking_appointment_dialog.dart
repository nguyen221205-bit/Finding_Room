import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/room_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/notification_provider.dart';
import 'app_snackbar.dart';

class BookingAppointmentDialog extends StatefulWidget {
  final RoomEntity room;

  const BookingAppointmentDialog({super.key, required this.room});

  @override
  State<BookingAppointmentDialog> createState() =>
      _BookingAppointmentDialogState();
}

class _BookingAppointmentDialogState extends State<BookingAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController(
    text: '1',
  );
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin người dùng nếu có
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.currentUser != null) {
      _nameController.text = auth.currentUser!.username;
      _phoneController.text = auth.currentUser!.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _peopleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Chọn ngày hẹn xem phòng',
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Chọn giờ hẹn xem phòng',
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final String minutes = dt.minute.toString().padLeft(2, '0');
    final String hours = dt.hour.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    return '$hours:$minutes ngày $day/$month/${dt.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      AppSnackbar.error(context, 'Vui lòng chọn thời gian hẹn.');
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      AppSnackbar.error(context, 'Thời gian hẹn phải nằm trong tương lai.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final String tenantId = auth.userId;

    if (tenantId.isEmpty) {
      AppSnackbar.error(context, 'Bạn cần đăng nhập để đặt lịch.');
      return;
    }

    setState(() => _isSubmitting = true);

    final appointmentProvider = context.read<AppointmentProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final String landlordId = widget.room.ownerId.isEmpty
        ? 'unknown'
        : widget.room.ownerId;

    final appointment = await appointmentProvider.createAppointment(
      roomId: widget.room.id,
      landlordId: landlordId,
      tenantId: tenantId,
      tenantName: _nameController.text.trim(),
      tenantPhone: _phoneController.text.trim(),
      numberOfPeople: int.tryParse(_peopleController.text) ?? 1,
      appointmentTime: _selectedDateTime!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (appointment != null) {
      // Gửi thông báo cho chủ nhà
      final String timeStr = _formatDateTime(_selectedDateTime!);
      final String tenantName = _nameController.text.trim();
      await notificationProvider.createNotification(
        userId: landlordId,
        title: 'Yêu cầu xem phòng mới',
        content: '$tenantName đã gửi yêu cầu xem phòng vào lúc $timeStr.',
        type: NotificationType.appointmentCreated,
        relatedId: appointment.id,
      );

      if (!mounted) return;
      AppSnackbar.show(context, 'Đặt lịch xem phòng thành công!');
      Navigator.of(context).pop(true);
    } else {
      AppSnackbar.error(
        context,
        appointmentProvider.error ??
            'Đặt lịch xem phòng thất bại. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đặt lịch xem phòng',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Text(
                  widget.room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Họ và tên
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên của bạn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Số điện thoại
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại liên hệ',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Số lượng người đi cùng
                TextFormField(
                  controller: _peopleController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số lượng người đi xem',
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số lượng người';
                    }
                    final int? count = int.tryParse(val);
                    if (count == null || count <= 0) {
                      return 'Số lượng người phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Thời gian hẹn
                InkWell(
                  onTap: _isSubmitting ? null : _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.calendar_today_outlined,
                          color: _selectedDateTime == null
                              ? Colors.grey
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDateTime == null
                                ? 'Chọn thời gian hẹn *'
                                : _formatDateTime(_selectedDateTime!),
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDateTime == null
                                  ? theme.hintColor
                                  : theme.colorScheme.onSurface,
                              fontWeight: _selectedDateTime == null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: theme.hintColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ghi chú
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (Không bắt buộc)',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Xác nhận
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác nhận đặt lịch',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
