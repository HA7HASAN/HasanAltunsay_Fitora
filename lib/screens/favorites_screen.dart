import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Product> products;
  final Set<int> favoriteIds;
  final Function(Product) onFavoriteTap;
  final Function(Product) onProductTap;

  const FavoritesScreen({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.onFavoriteTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = products
        .where((product) => favoriteIds.contains(product.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAVORİLERİM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: favoriteProducts.isEmpty
          ? _buildEmptyFavorites()
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: favoriteProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];

                return ProductCard(
                  product: product,
                  isFavorite: true,
                  onFavoriteTap: () => onFavoriteTap(product),
                  onTap: () => onProductTap(product),
                );
              },
            ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                color: AppTheme.primary,
                size: 65,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Henüz favorin yok!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Beğendiğin ürünleri kalp simgesine\nbasarak favorilerine ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
