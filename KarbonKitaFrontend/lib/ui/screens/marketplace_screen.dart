import 'package:flutter/material.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPointsAndWalletRow(),
              const SizedBox(height: 20),
              _buildCategoryChips(),
              const SizedBox(height: 20),
              _buildBanner(),
              const SizedBox(height: 25),
              _buildRecommendationsHeader(),
              const SizedBox(height: 15),
              _buildProductsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Green Market Place',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E6C46),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsAndWalletRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/ecopoints.png', width: 20, height: 20, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green, size: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Poin: ',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Text(
                  '1.250',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_wallet, size: 18),
            label: const Text('Dompet Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8039),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'label': 'Semua', 'icon': Icons.eco},
      {'label': 'Voucher UMKM', 'icon': Icons.storefront},
      {'label': 'Donasi Pohon', 'icon': Icons.park},
      {'label': 'Produk', 'icon': Icons.shopping_bag_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (index) {
          bool isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categories[index]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        'assets/images/bannermarketplace.png',
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildRecommendationsHeader() {
    return Row(
      children: [
        Image.asset('assets/images/ecopoints.png', width: 20, height: 20, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green, size: 20)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Rekomendasi Untukmu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
              Icon(Icons.chevron_right, color: Colors.green, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.62,
      children: [
        _buildProductCard(
          imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80',
          storeName: 'Kopi Lokal',
          category: 'Minuman',
          isUmkm: true,
          title: 'Voucher Rp 20.000',
          points: '500',
        ),
        _buildProductCard(
          imageUrl: 'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=400&q=80',
          storeName: 'LindungiHutan',
          category: 'Donasi',
          isUmkm: true,
          title: 'Donasi 1 Bibit Mangrove',
          points: '1000',
        ),
        _buildProductCard(
          imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&q=80',
          storeName: 'Dapur Sehat Ibu',
          category: 'Makanan',
          isUmkm: true,
          title: 'Voucher Nasi Ayam',
          points: '750',
        ),
        _buildProductCard(
          imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400&q=80',
          storeName: 'Kopi Lokal',
          category: 'Minuman',
          isUmkm: true,
          title: 'Es Kopi Susu Aren',
          points: '300',
        ),
      ],
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required String storeName,
    required String category,
    required bool isUmkm,
    required String title,
    required String points,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.brown.shade100,
                        child: Text(
                          storeName[0],
                          style: TextStyle(fontSize: 10, color: Colors.brown.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                                ),
                                if (isUmkm) ...[
                                  const SizedBox(width: 4),
                                  Image.asset('assets/images/ecopoints.png', width: 12, height: 12, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green, size: 12)),
                                  const SizedBox(width: 2),
                                  const Text('UMKM', style: TextStyle(fontSize: 8, color: Colors.grey)),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8039),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF1B8039),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF1B8039), width: 1),
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/ecopoints.png', width: 14, height: 14, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Color(0xFF1B8039), size: 14)),
                            const SizedBox(width: 4),
                            Text(
                              'Tukar $points Poin',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
