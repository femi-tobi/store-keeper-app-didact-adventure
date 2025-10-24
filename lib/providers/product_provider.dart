import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;
  Database? _db;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  // -------------------------------------------------
  // Initialise DB (called from main.dart)
  // -------------------------------------------------
  Future<void> initDatabase() async {
    _isLoading = true;
    notifyListeners();

    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'storekeeper.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            image_path TEXT
          )
        ''');
      },
    );

    await _loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------------------------
  // Load all from DB
  // -------------------------------------------------
  Future<void> _loadProducts() async {
    final maps = await _db!.query('products');
    _products = maps.map(Product.fromMap).toList();
  }

  // -------------------------------------------------
  // CRUD – placeholders (full impl in next step)
  // -------------------------------------------------
  Future<void> addProduct(Product p) async {
    final id = await _db!.insert('products', p.toMap());
    final newProduct = p.copyWith(id: id);
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product p) async {
    await _db!.update(
      'products',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    final idx = _products.indexWhere((e) => e.id == p.id);
    if (idx != -1) _products[idx] = p;
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
    _products.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}