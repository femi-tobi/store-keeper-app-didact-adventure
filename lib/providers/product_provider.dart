import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  Database? _db;
  bool _isLoading = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;


  Future<void> initDatabase() async {
    _isLoading = true;
    notifyListeners();

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'storekeeper.db');

    _db = await openDatabase(
      path,
      version: 2, // Increased version for migration
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );

    await _loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        stock INTEGER NOT NULL,
        price REAL NOT NULL,
        image_path TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN description TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE products ADD COLUMN stock INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _loadProducts() async {
    final List<Map<String, dynamic>> maps = await _db!.query('products');
    _products = maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> addProduct(Product product) async {
    final id = await _db!.insert('products', product.toMap());
    final newProduct = product.copyWith(id: id);
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db!.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> deleteProductWithImage(int id) async {
    final product = _products.firstWhere((p) => p.id == id, orElse: () => Product(name: '', description: '', stock: 0, price: 0));
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      final file = File(product.imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await deleteProduct(id);
  }
}