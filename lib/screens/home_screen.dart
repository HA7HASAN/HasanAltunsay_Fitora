import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/product_data.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_navigation.dart';

import 'product_detail_screen.dart';
import 'catalog_screen.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Product>> _productsFuture;

  int _currentIndex = 0;

  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  final Set<int> _favoriteIds = {};
  final Map<int, int> _cartItems = {};

  final List<String> _categories = [
    'Tümü',
    'Ayakkabı',
    'Giyim',
    'Ekipman',
    'Aksesuar',
  ];

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductData.loadProducts();
    _loadSavedData();
  }

  // Kaydedilmiş sepet ve favorileri yükle
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFavorites = prefs.getStringList('fitora_favorites') ?? [];
    final savedCart = prefs.getString('fitora_cart');

    final favoriteIds = savedFavorites
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    Map<int, int> cartItems = {};

    if (savedCart != null) {
      try {
        final decodedCart = jsonDecode(savedCart) as Map<String, dynamic>;

        cartItems = decodedCart.map(
          (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
        );
      } catch (_) {
        cartItems = {};
      }
    }

    if (!mounted) return;

    setState(() {
      _favoriteIds
        ..clear()
        ..addAll(favoriteIds);

      _cartItems
        ..clear()
        ..addAll(cartItems);
    });
  }

  // Sepet ve favorileri telefona kaydet
  Future<void> _saveSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'fitora_favorites',
      _favoriteIds.map((id) => id.toString()).toList(),
    );

    await prefs.setString(
      'fitora_cart',
      jsonEncode(
        _cartItems.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  // Sepete ürün ekle
  void _addToCart(Product product) {
    setState(() {
      _cartItems.update(
        product.id,
        (quantity) => quantity + 1,
        ifAbsent: () => 1,
      );
    });

    _saveSavedData();
  }

  // Sepetteki ürün adedini azalt
  void _decreaseQuantity(Product product) {
    setState(() {
      final quantity = _cartItems[product.id] ?? 0;

      if (quantity <= 1) {
        _cartItems.remove(product.id);
      } else {
        _cartItems[product.id] = quantity - 1;
      }
    });

    _saveSavedData();
  }

  // Ürünü sepetten tamamen kaldır
  void _removeFromCart(Product product) {
    setState(() {
      _cartItems.remove(product.id);
    });

    _saveSavedData();
  }

  // Favori durumunu değiştir
  void _toggleFavorite(Product product) {
    setState(() {
      if (_favoriteIds.contains(product.id)) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id);
      }
    });

    _saveSavedData();
  }

  // Sepetteki toplam ürün adedi
  int get _cartCount {
    return _cartItems.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // Ürün detayını aç
  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            _addToCart(product);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ürünler yüklenemedi: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final products = snapshot.data ?? [];

          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildHome(products),

              CatalogScreen(
                products: products,
                favoriteIds: _favoriteIds,
                onFavoriteTap: _toggleFavorite,
                onProductTap: _openProductDetail,
              ),

              FavoritesScreen(
                products: products,
                favoriteIds: _favoriteIds,
                onFavoriteTap: _toggleFavorite,
                onProductTap: _openProductDetail,
              ),

              CartScreen(
                products: products,
                cartItems: _cartItems,
                onIncrease: _addToCart,
                onDecrease: _decreaseQuantity,
                onRemove: _removeFromCart,
              ),
            ],
          );
        },
      ),

      // Alt navigasyon
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        cartCount: _cartCount,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  // Ana sayfa tasarımı
  Widget _buildHome(List<Product> products) {
    final filteredProducts = products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marka alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FITORA',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'SPORTS & FITNESS',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_cartCount > 0)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Karşılama
            const Text(
              'POTANSİYELİNİ',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'KEŞFET.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 35,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 20),

            // Kampanya kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A45), Color(0xFFDB431F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRAIN HARDER.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'LIVE STRONGER.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hedeflerine ulaşmak için ihtiyacın olan her şey.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Text(
                        'FITORA COLLECTION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Arama
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Ürün veya kategori ara...',
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
            ),

            const SizedBox(height: 25),

            // Kategoriler
            const Text(
              'Kategoriler',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // Ürün başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Öne Çıkan Ürünler',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredProducts.length} ürün',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Ürün kartları
            if (filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Center(
                  child: Text(
                    'Aradığın ürün bulunamadı.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];

                  return ProductCard(
                    product: product,
                    isFavorite: _favoriteIds.contains(product.id),
                    onFavoriteTap: () {
                      _toggleFavorite(product);
                    },
                    onTap: () {
                      _openProductDetail(product);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
