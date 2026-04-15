import 'package:coffee_lover/models/shop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shop model', () {
    test('displayName prefers Vietnamese name when present', () {
      const shop = Shop(
        id: 'a',
        name: 'The Note Coffee',
        nameVi: 'Cà Phê Nốt',
        lat: 21.03,
        lng: 105.85,
      );
      expect(shop.displayName, 'Cà Phê Nốt');
    });

    test('displayName falls back to English name when nameVi is empty', () {
      const shop = Shop(
        id: 'a',
        name: 'The Note Coffee',
        nameVi: '',
        lat: 21.03,
        lng: 105.85,
      );
      expect(shop.displayName, 'The Note Coffee');
    });

    test('roundtrip through JSON preserves core fields', () {
      const shop = Shop(
        id: 'a',
        name: 'X',
        lat: 21.0,
        lng: 105.8,
        priceLevel: 2,
        tags: ['quiet', 'wifi'],
        source: ShopSource.curatedIg,
        sourceUrl: 'https://instagram.com/p/abc',
      );
      final back = Shop.fromJson(shop.toJson());
      expect(back.name, shop.name);
      expect(back.lat, shop.lat);
      expect(back.lng, shop.lng);
      expect(back.priceLevel, 2);
      expect(back.tags, ['quiet', 'wifi']);
      expect(back.source, ShopSource.curatedIg);
      expect(back.sourceUrl, 'https://instagram.com/p/abc');
    });
  });
}
