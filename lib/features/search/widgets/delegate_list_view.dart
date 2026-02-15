import 'package:flutter/material.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/widgets/delegate_card.dart';

//โหลดข้อมูล delegate จาก API และแสดงใน ListView
class DelegateListView extends StatelessWidget {
  final DelegateSearchResponse response;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const DelegateListView({
    super.key,
    required this.response,
    required this.scrollController,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    final delegates = response.delegates;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: delegates.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == delegates.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return DelegateCard(delegate: delegates[index]);
      },
    );
  }
}
