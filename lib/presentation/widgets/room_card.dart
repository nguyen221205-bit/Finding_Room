import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/room_entity.dart';
import 'animated_favorite_button.dart';
import 'app_image.dart';

class RoomCard extends StatelessWidget {
  final RoomEntity room;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRented = room.availability == RoomAvailability.rented;
    return Opacity(
      opacity: isRented ? 0.65 : 1.0,
      child: InkWell(
        borderRadius: AppRadius.largeAll,
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: AppSpacing.paddingAllLg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.mediumAll,
                  child: SizedBox(
                    width: 104,
                    height: 88,
                    child: AppImage(imagePath: room.primaryImageUrl),
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              room.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AnimatedFavoriteButton(
                            isFavorite: room.isFavorite,
                            onTap: onToggleFavorite,
                          ),
                        ],
                      ),
                      AppSpacing.vXs,
                      Text(
                        Formatters.pricePerMonth(room.price),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _InfoPill(
                            icon: Icons.square_foot,
                            text: '${room.area.toStringAsFixed(0)} m²',
                          ),
                          _InfoPill(
                            icon: Icons.person,
                            text: '${room.capacity} người',
                          ),
                          _AvailabilityPill(availability: room.availability),
                        ],
                      ),
                    ],
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.shimmerHighlight,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final RoomAvailability availability;

  const _AvailabilityPill({required this.availability});

  @override
  Widget build(BuildContext context) {
    final bool isRented = availability == RoomAvailability.rented;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRented ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: isRented ? Colors.red.shade200 : Colors.green.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isRented ? Icons.lock : Icons.check_circle_outline,
            size: 14,
            color: isRented ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isRented ? 'Đã thuê' : 'Còn trống',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isRented ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
