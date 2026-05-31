import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/room_provider.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../room/room_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _district;
  String? _priceOption;
  String _sortBy = 'Mới nhất';
  final Set<String> _amenities = <String>{};

  final List<String> _districts = const <String>[
    'Tất cả',
    'Quận 1',
    'Quận 2',
    'Quận 3',
    'Quận 5',
    'Quận 10',
    'Bình Thạnh',
    'Gò Vấp',
    'Tân Bình',
    'Phú Nhuận',
  ];

  final List<String> _priceOptions = const <String>[
    'Tất cả',
    'Dưới 3 triệu',
    '3 - 5 triệu',
    '5 - 8 triệu',
    'Trên 8 triệu',
  ];

  final List<String> _sortOptions = const <String>[
    'Mới nhất',
    'Giá tăng dần',
    'Giá giảm dần',
  ];

  @override
  void initState() {
    super.initState();
    final RoomProvider rp = context.read<RoomProvider>();
    Future<void>.microtask(() {
      if (!mounted) return;
      _searchCtrl.text = rp.searchQuery;
      _district = rp.filters.district ?? 'Tất cả';
      _priceOption = rp.filters.priceOption ?? 'Tất cả';
      _sortBy = rp.filters.sortBy;
      _amenities
        ..clear()
        ..addAll(rp.filters.amenities);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _apply(RoomProvider rp) {
    rp.setSearchQuery(_searchCtrl.text);
    rp.setDistrict(_district == 'Tất cả' ? null : _district);
    rp.setPriceOption(_priceOption == 'Tất cả' ? null : _priceOption);
    rp.setSortBy(_sortBy);
    rp.setAmenities(_amenities);
  }

  void _showAmenitiesBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Chọn tiện ích',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  AppSpacing.vMd,
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.amenities.map((String a) {
                      final bool checked = _amenities.contains(a);
                      return FilterChip(
                        selected: checked,
                        label: Text(a),
                        onSelected: (bool v) {
                          setModalState(() {
                            if (v) {
                              _amenities.add(a);
                            } else {
                              _amenities.remove(a);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.vLg,
                  PrimaryButton(
                    label: 'Áp dụng',
                    onPressed: () {
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (BuildContext context, RoomProvider roomProvider, _) {
        final rooms = roomProvider.approvedFilteredRooms;
        return DismissKeyboard(
          child: Scaffold(
            appBar: AppBar(title: const Text('Tìm kiếm & Lọc')),
            body: SafeArea(
              child: CustomScrollView(
                key: const PageStorageKey<String>('search_scroll_key'),
                slivers: <Widget>[
                  SliverPadding(
                    padding: AppSpacing.paddingAllLg.copyWith(bottom: 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Nhập tiêu đề hoặc địa chỉ...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        AppSpacing.vMd,

                        // District drop down
                        DropdownButtonFormField<String>(
                          initialValue: _district,
                          decoration: const InputDecoration(
                            labelText: 'Quận / Huyện',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          items: _districts.map((String d) {
                            return DropdownMenuItem<String>(
                              value: d,
                              child: Text(d),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            setState(() => _district = val);
                          },
                        ),
                        AppSpacing.vMd,

                        // Price option drop down
                        DropdownButtonFormField<String>(
                          initialValue: _priceOption,
                          decoration: const InputDecoration(
                            labelText: 'Khoảng giá',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          items: _priceOptions.map((String p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(p),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            setState(() => _priceOption = val);
                          },
                        ),
                        AppSpacing.vMd,

                        // Sort option drop down
                        DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Sắp xếp theo',
                            prefixIcon: Icon(Icons.sort_outlined),
                          ),
                          items: _sortOptions.map((String s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _sortBy = val);
                            }
                          },
                        ),
                        AppSpacing.vLg,

                        // Amenities button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Tiện ích',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showAmenitiesBottomSheet,
                              icon: const Icon(Icons.apps_outlined),
                              label: Text(
                                _amenities.isEmpty
                                    ? 'Chọn tiện ích'
                                    : 'Đã chọn (${_amenities.length})',
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vLg,

                        // Apply and Reset Buttons
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: PrimaryButton(
                                label: 'Áp dụng bộ lọc',
                                icon: Icons.tune,
                                onPressed: () => _apply(roomProvider),
                              ),
                            ),
                            AppSpacing.hMd,
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchCtrl.clear();
                                  _district = 'Tất cả';
                                  _priceOption = 'Tất cả';
                                  _sortBy = 'Mới nhất';
                                  _amenities.clear();
                                });
                                roomProvider.clearFilters();
                              },
                              child: const Text('Làm mới'),
                            ),
                          ],
                        ),
                        AppSpacing.vLg,
                        const SectionHeader(title: 'Kết quả tìm kiếm'),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: _buildSliverResults(roomProvider, rooms),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverResults(RoomProvider roomProvider, List<dynamic> rooms) {
    if (roomProvider.isLoading && rooms.isEmpty) {
      return const SliverToBoxAdapter(
        child: LoadingPlaceholderList(key: ValueKey<String>('search_loading')),
      );
    }

    if (rooms.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          key: ValueKey<String>('search_empty'),
          icon: Icons.filter_alt_off,
          title: 'Không tìm thấy phòng',
          message: 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm khác.',
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
            onToggleFavorite: () => roomProvider.toggleFavorite(room.id),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RoomDetailScreen(roomId: room.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
