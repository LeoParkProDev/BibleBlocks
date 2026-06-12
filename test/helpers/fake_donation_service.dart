import 'dart:async';

import 'package:bible_blocks/services/donation_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class DummyIAP implements InAppPurchase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductDetails makeProduct(String id, double price, {String? priceLabel}) =>
    ProductDetails(
      id: id,
      title: id,
      description: id,
      price: priceLabel ?? '₩${price.toInt()}',
      rawPrice: price,
      currencyCode: 'KRW',
    );

PurchaseDetails makePurchased({String productId = 'donation_1000'}) =>
    PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: null,
      status: PurchaseStatus.purchased,
    );

/// 플랫폼 채널 없이 프로바이더/위젯 로직을 검증하기 위한 후원 서비스 페이크.
class FakeDonationService extends DonationService {
  FakeDonationService(this._products) : super(DummyIAP());

  final List<ProductDetails> _products;
  final bought = <ProductDetails>[];
  final controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<List<ProductDetails>> loadProducts() async => _products;

  @override
  Future<void> buy(ProductDetails product) async => bought.add(product);

  @override
  Future<DonationPhase> handlePurchase(PurchaseDetails purchase) async =>
      purchase.status == PurchaseStatus.purchased
          ? DonationPhase.success
          : DonationPhase.error;
}
