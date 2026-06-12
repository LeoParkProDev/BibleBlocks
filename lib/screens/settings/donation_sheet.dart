import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../providers/donation_provider.dart';
import '../../theme/app_colors.dart';

/// 후원 상품 선택 바텀시트 — 상품 탭 시 시트를 닫고 구매를 시작한다.
/// 결제 결과 처리(감사 다이얼로그/스낵바)는 SettingsScreen의 listener가 담당.
class DonationSheet extends ConsumerWidget {
  const DonationSheet({super.key});

  static const _labels = {
    'donation_1000': '커피 한 잔 후원',
    'donation_5000': '따뜻한 응원 후원',
  };
  static const _icons = {
    'donation_1000': Icons.coffee,
    'donation_5000': Icons.volunteer_activism,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(donationProvider);

    Widget body;
    if (products.isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (products.hasError || (products.value ?? []).isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          '지금은 스토어에 연결할 수 없습니다.\n잠시 후 다시 시도해 주세요.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final product in products.value!) _productTile(context, ref, product),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: AppColors.gold, size: 20),
                SizedBox(width: 8),
                Text(
                  '개발자 후원하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '보상 없는 순수 후원이에요.\n보내주신 마음은 BibleBlocks를 만드는 데 큰 힘이 됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }

  Widget _productTile(
      BuildContext context, WidgetRef ref, ProductDetails product) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        _icons[product.id] ?? Icons.favorite_border,
        color: AppColors.primary,
      ),
      title: Text(
        _labels[product.id] ?? product.title,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      trailing: Text(
        product.price,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
      ),
      onTap: () {
        // 시트를 먼저 닫고 구매 시작 — 결과는 설정 화면 listener가 받는다
        Navigator.pop(context);
        ref.read(donationProvider.notifier).purchase(product);
      },
    );
  }
}
