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
}
