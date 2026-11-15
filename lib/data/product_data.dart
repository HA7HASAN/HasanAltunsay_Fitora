import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/product.dart';

class ProductData {
  static Future<List<Product>> loadProducts() async {
    final String response = await rootBundle.loadString(
      'assets/data/products.json',
    );

    final List<dynamic> data = jsonDecode(response);

    return data.map((item) {
      return Product.fromJson(item);
    }).toList();
  }
}
