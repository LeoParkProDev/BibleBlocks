import 'dart:async';

import 'package:bible_blocks/services/donation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

ProductDetails _product(String id, double price) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: '₩${price.toInt()}',
      rawPrice: price,
      currencyCode: 'KRW',
    );

PurchaseDetails _purchase(PurchaseStatus status, {bool pending = false}) {
  final p = PurchaseDetails(
    productID: 'donation_1000',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  );
  p.pendingCompletePurchase = pending;
  return p;
}

/// in_app_purchase 플러그인 페이크 — 플랫폼 채널 없이 서비스 로직만 검증.
class FakeIAP implements InAppPurchase {
  FakeIAP({this.available = true, List<ProductDetails>? products})
      : products = products ?? [];

  bool available;
  List<ProductDetails> products;
  final completed = <PurchaseDetails>[];
  PurchaseParam? lastBuyParam;
  final controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails:
          products.where((p) => identifiers.contains(p.id)).toList(),
      notFoundIDs: identifiers
          .where((id) => !products.any((p) => p.id == id))
          .toList(),
    );
  }

  @override
  Future<bool> buyConsumable(
      {required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    lastBuyParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('loadProducts', () {
    test('상품을 가격 오름차순으로 정렬해 반환한다', () async {
      final iap = FakeIAP(products: [
        _product('donation_5000', 5000),
        _product('donation_1000', 1000),
      ]);
      final result = await DonationService(iap).loadProducts();
      expect(
        result.map((p) => p.id).toList(),
        ['donation_1000', 'donation_5000'],
      );
    });

    test('스토어 사용 불가면 빈 목록을 반환한다', () async {
      final iap = FakeIAP(
        available: false,
        products: [_product('donation_1000', 1000)],
      );
      expect(await DonationService(iap).loadProducts(), isEmpty);
    });
  });

  group('buy', () {
    test('소모성 구매(buyConsumable)로 상품을 구매한다', () async {
      final iap = FakeIAP();
      await DonationService(iap).buy(_product('donation_1000', 1000));
      expect(iap.lastBuyParam?.productDetails.id, 'donation_1000');
    });
  });

  group('handlePurchase', () {
    test('구매 완료면 completePurchase 호출 후 success를 반환한다', () async {
      final iap = FakeIAP();
      final purchase = _purchase(PurchaseStatus.purchased, pending: true);
      final phase = await DonationService(iap).handlePurchase(purchase);
      expect(phase, DonationPhase.success);
      expect(iap.completed, [purchase]);
    });

    test('취소면 canceled를 반환하고 완료 처리하지 않는다', () async {
      final iap = FakeIAP();
      final phase = await DonationService(iap)
          .handlePurchase(_purchase(PurchaseStatus.canceled));
      expect(phase, DonationPhase.canceled);
      expect(iap.completed, isEmpty);
    });

    test('오류면 error를 반환한다', () async {
      final iap = FakeIAP();
      final phase = await DonationService(iap)
          .handlePurchase(_purchase(PurchaseStatus.error));
      expect(phase, DonationPhase.error);
    });
  });
}
