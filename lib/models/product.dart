class Product {
  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String image;
  final double rating;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.image,
    required this.rating,
  });

  // JSON verisini Product nesnesine dönüştürür.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      image: json['image'],
      rating: (json['rating'] as num).toDouble(),
    );
  }

  // Product nesnesini JSON formatına dönüştürür.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'image': image,
      'rating': rating,
    };
  }
}
