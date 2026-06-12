import 'package:in_app_purchase/in_app_purchase.dart';

/// 후원 구매 진행 단계.
enum DonationPhase { idle, pending, success, canceled, error }

/// 개발자 후원 IAP 서비스 — in_app_purchase 래핑.
/// 소모성 상품 2종(donation_1000 / donation_5000), 보상 없는 순수 후원.
class DonationService {
  DonationService(this._iap);

  final InAppPurchase _iap;

  static const Set<String> productIds = {'donation_1000', 'donation_5000'};

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// 스토어에서 후원 상품 조회 — 가격 오름차순. 스토어 사용 불가 시 빈 목록.
  Future<List<ProductDetails>> loadProducts() async {
    if (!await _iap.isAvailable()) return [];
    final response = await _iap.queryProductDetails(productIds);
    final products = [...response.productDetails]
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return products;
  }

  Future<void> buy(ProductDetails product) => _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  /// 구매 업데이트 1건 처리 — 스토어 완료 처리(completePurchase) 후 단계 반환.
  Future<DonationPhase> handlePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        return DonationPhase.success;
      case PurchaseStatus.canceled:
        return DonationPhase.canceled;
      case PurchaseStatus.error:
        return DonationPhase.error;
      case PurchaseStatus.pending:
        return DonationPhase.pending;
    }
  }
}
