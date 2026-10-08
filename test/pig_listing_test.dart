import 'package:flutter_test/flutter_test.dart';
import 'package:pigworld_buyer/main.dart';

void main() {
  test('parses a marketplace listing for buyer display', () {
    final listing = PigListing.fromJson({
      'id': 7,
      'title': 'Healthy weaners',
      'breed': 'Large White',
      'quantity': 6,
      'price_per_pig': '18000.00',
      'currency': 'KES',
      'farm_name': 'Green Acres',
      'farm_location': 'Nakuru',
      'age_weeks': 10,
      'weight_kg': '18.50',
    });

    expect(listing.id, '7');
    expect(listing.breed, 'Large White');
    expect(listing.quantity, 6);
    expect(listing.pricePerPig, 18000);
    expect(listing.location, 'Nakuru');
    expect(listing.weightKg, 18.5);
    expect(listing.searchableText, contains('green acres'));
  });

  test('parses delivery request status and farm information', () {
    final delivery = BuyerDelivery.fromJson({
      'id': '12',
      'buyer_name': 'Amina',
      'phone': '+254700000005',
      'quantity': 2,
      'status': 'accepted',
      'message': 'Arrange delivery',
      'created_at': '2026-10-08T08:00:00+00:00',
      'listing': {
        'title': 'Healthy weaners',
        'breed': 'Large White',
        'farm_name': 'Green Acres',
        'farm_location': 'Nakuru',
        'price_per_pig': '18000.00',
        'currency': 'KES',
      },
    });

    expect(delivery.status, 'accepted');
    expect(delivery.listingTitle, 'Healthy weaners');
    expect(delivery.farmName, 'Green Acres');
    expect(delivery.quantity, 2);
    expect(delivery.pricePerPig, 18000);
  });
}
