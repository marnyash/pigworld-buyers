import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const _green = Color(0xFF176B4D);
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.pigworldsmart.com/api/v1',
);

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PigWorld Buyer',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
      scaffoldBackgroundColor: const Color(0xFFF5F7F4),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const BuyerHomePage(),
  );
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final _api = BuyerMarketplaceApi(Dio(BaseOptions(baseUrl: _baseUrl)));
  late Future<List<PigListing>> _listingsFuture;
  String _search = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _api.fetchListings();
  }

  Future<void> _refresh() async {
    final future = _api.fetchListings();
    setState(() => _listingsFuture = future);
    try {
      await future;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh pigs: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PigWorld Market'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: _page == 0 ? _marketplace() : const _HowItWorksPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Find pigs'),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'How it works',
          ),
        ],
      ),
    );
  }

  Widget _marketplace() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search breed, farm or location',
          ),
          onChanged: (value) =>
              setState(() => _search = value.trim().toLowerCase()),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<PigListing>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _LoadError(
                error: snapshot.error!,
                onRetry: () =>
                    setState(() => _listingsFuture = _api.fetchListings()),
              );
            }
            final listings = (snapshot.data ?? const <PigListing>[])
                .where((listing) => listing.searchableText.contains(_search))
                .toList();
            if (listings.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.pets_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _search.isEmpty
                            ? 'No pigs are available right now.'
                            : 'No pigs match your search.',
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: listings.length,
                itemBuilder: (context, index) => _BuyerListingCard(
                  listing: listings[index],
                  onRequest: () => _showRequestDialog(listings[index]),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Future<void> _showRequestDialog(PigListing listing) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final message = TextEditingController();
    var submitting = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Request ${listing.title}'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Your name'),
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validEmail,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantity,
                      decoration: const InputDecoration(
                        labelText: 'Number of pigs',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Enter at least one pig.';
                        }
                        if (parsed > listing.quantity) {
                          return 'Only ${listing.quantity} pigs are listed.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: message,
                      decoration: const InputDecoration(
                        labelText: 'Message to the farm (optional)',
                      ),
                      maxLines: 3,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await _api.sendInquiry(
                          listingId: listing.id,
                          buyerName: name.text.trim(),
                          phone: phone.text.trim(),
                          email: email.text.trim(),
                          quantity: int.parse(quantity.text.trim()),
                          message: message.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your request was sent to the farm.',
                              ),
                            ),
                          );
                        }
                      } catch (exception) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            submitting = false;
                            error = 'Could not send your request: $exception';
                          });
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send request'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    quantity.dispose();
    message.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address.';
  }
}

class BuyerMarketplaceApi {
  BuyerMarketplaceApi(this._dio);

  final Dio _dio;

  Future<List<PigListing>> fetchListings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/marketplace/pigs',
      );
      final rows = response.data?['data'] as List<dynamic>? ?? const [];
      return rows
          .map((row) => PigListing.fromJson(row as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw StateError(_errorMessage(error));
    }
  }

  Future<void> sendInquiry({
    required String listingId,
    required String buyerName,
    required String phone,
    required String email,
    required int quantity,
    required String message,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/marketplace/pigs/$listingId/inquiries',
        data: {
          'buyer_name': buyerName,
          'phone': phone,
          if (email.isNotEmpty) 'email': email,
          'quantity': quantity,
          if (message.isNotEmpty) 'message': message,
        },
      );
    } on DioException catch (error) {
      throw StateError(_errorMessage(error));
    }
  }

  String _errorMessage(DioException error) {
    final responseMessage = error.response?.data is Map<String, dynamic>
        ? (error.response!.data as Map<String, dynamic>)['message']
        : null;
    if (responseMessage is String && responseMessage.isNotEmpty) {
      return responseMessage;
    }
    return error.message ?? 'Unable to reach the marketplace.';
  }
}

class PigListing {
  const PigListing({
    required this.id,
    required this.title,
    required this.breed,
    required this.quantity,
    required this.pricePerPig,
    required this.currency,
    required this.farmName,
    this.ageWeeks,
    this.weightKg,
    this.location,
    this.description,
  });

  final String id;
  final String title;
  final String breed;
  final int quantity;
  final double pricePerPig;
  final String currency;
  final String farmName;
  final int? ageWeeks;
  final double? weightKg;
  final String? location;
  final String? description;

  String get searchableText =>
      '$title $breed $farmName ${location ?? ''}'.toLowerCase();

  factory PigListing.fromJson(Map<String, dynamic> json) => PigListing(
    id: '${json['id'] ?? ''}',
    title: '${json['title'] ?? 'Pig listing'}',
    breed: '${json['breed'] ?? 'Unknown breed'}',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    pricePerPig: double.tryParse('${json['price_per_pig'] ?? 0}') ?? 0,
    currency: '${json['currency'] ?? 'KES'}',
    farmName: '${json['farm_name'] ?? 'Farm'}',
    ageWeeks: (json['age_weeks'] as num?)?.toInt(),
    weightKg: json['weight_kg'] == null
        ? null
        : double.tryParse('${json['weight_kg']}'),
    location: json['location'] as String? ?? json['farm_location'] as String?,
    description: json['description'] as String?,
  );
}

class _BuyerListingCard extends StatelessWidget {
  const _BuyerListingCard({required this.listing, required this.onRequest});

  final PigListing listing;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE9F2EC),
                foregroundColor: _green,
                child: const Icon(Icons.pets_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${listing.farmName} · ${listing.location ?? 'Location not specified'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: listing.breed, icon: Icons.pets_outlined),
              if (listing.ageWeeks != null)
                _Tag(
                  label: '${listing.ageWeeks} weeks',
                  icon: Icons.calendar_today_outlined,
                ),
              if (listing.weightKg != null)
                _Tag(
                  label: '${listing.weightKg} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              _Tag(
                label: '${listing.quantity} available',
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          if (listing.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(listing.description!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${listing.currency} ${listing.pricePerPig.toStringAsFixed(0)} each',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton(
                onPressed: onRequest,
                child: const Text('Contact farm'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text('Could not load pigs from the marketplace.'),
          const SizedBox(height: 6),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text(
        'Buy directly from farms',
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 14),
      _StepTile(
        number: '1',
        title: 'Find pigs',
        description:
            'Browse farm listings and compare breed, location and price.',
      ),
      _StepTile(
        number: '2',
        title: 'Contact the farm',
        description:
            'Send your name, phone number and the number of pigs you need.',
      ),
      _StepTile(
        number: '3',
        title: 'Agree directly',
        description:
            'The farm will contact you to confirm availability, collection and payment.',
      ),
    ],
  );
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });
  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        child: Text(number),
      ),
      title: Text(title),
      subtitle: Text(description),
    ),
  );
}
