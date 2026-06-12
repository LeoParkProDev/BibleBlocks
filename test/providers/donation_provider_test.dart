import 'package:bible_blocks/providers/donation_provider.dart';
import 'package:bible_blocks/services/donation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_donation_service.dart';

ProviderContainer _container(FakeDonationService fake) {
  final container = ProviderContainer(
    overrides: [donationServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('빌드 시 서비스에서 상품 목록을 로드한다', () async {
    final fake = FakeDonationService([
      makeProduct('donation_1000', 1000),
      makeProduct('donation_5000', 5000),
    ]);
    final container = _container(fake);

    final products = await container.read(donationProvider.future);

    expect(products.map((p) => p.id), ['donation_1000', 'donation_5000']);
  });

  test('purchase는 서비스 buy를 호출하고 단계를 pending으로 만든다', () async {
    final fake = FakeDonationService([makeProduct('donation_1000', 1000)]);
    final container = _container(fake);
    final products = await container.read(donationProvider.future);

    await container.read(donationProvider.notifier).purchase(products.first);

    expect(fake.bought.map((p) => p.id), ['donation_1000']);
    expect(container.read(donationPhaseProvider), DonationPhase.pending);
  });

  test('구매 완료 이벤트가 오면 단계가 success가 된다', () async {
    final fake = FakeDonationService([makeProduct('donation_1000', 1000)]);
    final container = _container(fake);
    await container.read(donationProvider.future);

    fake.controller.add([makePurchased()]);
    await pumpEventQueue();

    expect(container.read(donationPhaseProvider), DonationPhase.success);
  });

  test('단계는 reset으로 idle로 되돌릴 수 있다', () async {
    final fake = FakeDonationService([]);
    final container = _container(fake);

    container.read(donationPhaseProvider.notifier).set(DonationPhase.error);
    container.read(donationPhaseProvider.notifier).reset();

    expect(container.read(donationPhaseProvider), DonationPhase.idle);
  });
}
