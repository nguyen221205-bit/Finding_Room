import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/room_provider.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../room/room_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final RoomProvider roomProvider = context.read<RoomProvider>();
    Future<void>.microtask(() => roomProvider.loadRoomsIfNeeded());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final RoomProvider roomProvider = context.read<RoomProvider>();
    _searchCtrl.text = roomProvider.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (BuildContext context, RoomProvider roomProvider, _) {
        final rooms = roomProvider.approvedFilteredRooms;
        return DismissKeyboard(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Room Rental Finder'),
              actions: <Widget>[
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No notifications (mock).')),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => roomProvider.loadRooms(),
                child: CustomScrollView(
                  key: const PageStorageKey<String>('home_scroll_key'),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: AppSpacing.paddingAllLg.copyWith(bottom: 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(<Widget>[
                          TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            onChanged: roomProvider.setSearchQuery,
                            decoration: const InputDecoration(
                              hintText: 'Search by title or address...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          AppSpacing.vMd,
                          const BannerCarousel(imageUrls: AppConstants.bannerImages),
                          AppSpacing.vLg,
                          SectionHeader(
                            title: 'Rooms',
                            trailing: TextButton(
                              onPressed: roomProvider.clearFilters,
                              child: const Text('Clear'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      sliver: _buildSliverRoomsContent(roomProvider, rooms),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverRoomsContent(RoomProvider roomProvider, List<dynamic> rooms) {
    if (roomProvider.isLoading && rooms.isEmpty) {
      return const SliverToBoxAdapter(
        child: LoadingPlaceholderList(
          key: ValueKey<String>('rooms_loading'),
        ),
      );
    }

    if (roomProvider.error != null) {
      return SliverToBoxAdapter(
        child: EmptyState(
          key: const ValueKey<String>('rooms_error'),
          icon: Icons.error_outline,
          title: roomProvider.error!,
          message: 'Pull down to retry.',
          actionLabel: 'Retry',
          onAction: roomProvider.loadRooms,
        ),
      );
    }

    if (rooms.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          key: ValueKey<String>('rooms_empty'),
          icon: Icons.search_off,
          title: 'No rooms found',
          message: 'Try different keywords or filters.',
        ),
      );
    }

    return SliverList.builder(
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: RoomCard(
            room: room,
            onToggleFavorite: () =>
                roomProvider.toggleFavorite(room.id),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RoomDetailScreen(roomId: room.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
