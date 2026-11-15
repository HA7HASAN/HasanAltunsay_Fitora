import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/models/product.dart';

void main() {
  test('Product JSON donusumu dogru calisiyor', () {
    final product = Product(
      id: 1,
      name: 'Performance Running',
      category: 'Ayakkabı',
      description: 'Profesyonel spor ayakkabısı',
      price: 2499,
      image: '',
      rating: 4.8,
    );

    final json = product.toJson();
    final convertedProduct = Product.fromJson(json);

    expect(convertedProduct.id, 1);
    expect(convertedProduct.name, 'Performance Running');
    expect(convertedProduct.price, 2499);
    expect(convertedProduct.rating, 4.8);
  });
}
