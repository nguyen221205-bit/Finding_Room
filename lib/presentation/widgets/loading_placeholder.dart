import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class LoadingPlaceholderList extends StatelessWidget {
  final int itemCount;

  const LoadingPlaceholderList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(itemCount, (int index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: LoadingPlaceholderCard(),
        );
      }),
    );
  }
}

class LoadingPlaceholderCard extends StatelessWidget {
  const LoadingPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Row(
          children: <Widget>[
            _Block(width: 104, height: 88, radius: AppRadius.medium),
            AppSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  _Block(width: double.infinity, height: 16),
                  SizedBox(height: 10),
                  _Block(width: 120, height: 14),
                  SizedBox(height: 10),
                  _Block(width: 180, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Block({
    required this.width,
    required this.height,
    this.radius = AppRadius.small,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
