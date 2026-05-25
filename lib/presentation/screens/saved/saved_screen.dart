import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/room_card.dart';
import '../room/room_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (BuildContext context, FavoriteProvider fav, _) {
        final rooms = fav.favorites;
        return Scaffold(
          appBar: AppBar(title: const Text('Saved Rooms')),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: rooms.isEmpty
                  ? const EmptyState(
                      key: ValueKey<String>('saved_empty'),
                      icon: Icons.favorite_border,
                      title: 'No saved rooms',
                      message: 'Tap the heart icon to save rooms.',
                    )
                  : ListView.separated(
                      key: const PageStorageKey<String>('saved_scroll_key'),
                      padding: AppSpacing.paddingAllLg,
                      itemCount: rooms.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          AppSpacing.vMd,
                      itemBuilder: (BuildContext context, int i) {
                        final room = rooms[i];
                        return RoomCard(
                          room: room,
                          onToggleFavorite: () => fav.removeFavorite(room.id),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => RoomDetailScreen(roomId: room.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
