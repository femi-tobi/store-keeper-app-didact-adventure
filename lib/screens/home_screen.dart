import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete product?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.person), onPressed: () {}),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('4',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = provider.products;
          if (products.isEmpty) {
            return const Center(
              child: Text('No products yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: products.length,
            itemBuilder: (_, i) => _InventoryCard(product: products[i]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// SINGLE INVENTORY CARD – matches the design 1-to-1
// ---------------------------------------------------------------------
class _InventoryCard extends StatelessWidget {
  final Product product;
  const _InventoryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final delete = await HomeScreen()._confirmDelete(context);
        if (delete) {
          provider.deleteProduct(product.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted')),
          );
        }
        return false;
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/detail',
              arguments: product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- IMAGE ----
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _productImage(),
                ),
                const SizedBox(width: 12),

                // ---- TEXT CONTENT ----
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description (optional – we keep first 60 chars)
                      Text(
                        _shortDescription(),
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // In stock + plus button
                      Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 10, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'In stock: ${product.quantity}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // Quick-add one unit (optional feature)
                                final updated = product.copyWith(
                                    quantity: product.quantity + 1);
                                provider.updateProduct(updated);
                              },
                              child: const Icon(Icons.add, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Image with fallback placeholder (exactly like the mockup)
  // -----------------------------------------------------------------
  Widget _productImage() {
    const double size = 80;

    if (product.imagePath == null || product.imagePath!.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.inventory_2,
            size: 36, color: Colors.grey),
      );
    }

    final file = File(product.imagePath!);
    if (!file.existsSync()) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image,
            size: 36, color: Colors.grey),
      );
    }

    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image,
            size: 36, color: Colors.grey),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Short description – you can store a longer description later
  // -----------------------------------------------------------------
  String _shortDescription() {
    // For now we just show a static hint. Replace with real field later.
    const demo =
        'An elegant classic of highest quality. Brazil Campo Das Vertentes is a pure, fresh coffee with notes of dried fig, nougat, and chocolate.';
    return demo.length > 60 ? '${demo.substring(0, 60)}...' : demo;
  }
}