import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/donation_service.dart';

final donationServiceProvider = Provider<DonationService>(
  (ref) => DonationService(InAppPurchase.instance),
);

/// 후원 상품 목록 — 웹/스토어 사용 불가 시 빈 목록.
final donationProvider =
    AsyncNotifierProvider<DonationNotifier, List<ProductDetails>>(
        DonationNotifier.new);

/// 구매 진행 단계 — UI가 listen해서 감사 다이얼로그/스낵바를 띄운다.
final donationPhaseProvider =
    NotifierProvider<DonationPhaseNotifier, DonationPhase>(
        DonationPhaseNotifier.new);

class DonationNotifier extends AsyncNotifier<List<ProductDetails>> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Future<List<ProductDetails>> build() async {
    if (kIsWeb) return [];
    final service = ref.watch(donationServiceProvider);
    _subscription?.cancel();
    _subscription = service.purchaseStream.listen(_onPurchaseUpdates);
    ref.onDispose(() => _subscription?.cancel());
    return service.loadProducts();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    final service = ref.read(donationServiceProvider);
    for (final purchase in purchases) {
      final phase = await service.handlePurchase(purchase);
      ref.read(donationPhaseProvider.notifier).set(phase);
    }
  }

  Future<void> purchase(ProductDetails product) async {
    ref.read(donationPhaseProvider.notifier).set(DonationPhase.pending);
    try {
      await ref.read(donationServiceProvider).buy(product);
    } catch (_) {
      ref.read(donationPhaseProvider.notifier).set(DonationPhase.error);
    }
  }
}

class DonationPhaseNotifier extends Notifier<DonationPhase> {
  @override
  DonationPhase build() => DonationPhase.idle;

  void set(DonationPhase phase) => state = phase;

  void reset() => state = DonationPhase.idle;
}
