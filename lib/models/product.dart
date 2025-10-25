class Product {
  final int? id;
  final String name;
  final String description;
  final int stock;
  final double price;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.stock,
    required this.price,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stock': stock,
      'price': price,
      'image_path': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      stock: map['stock'] as int? ?? 0,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? stock,
    double? price,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}