import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storekeeper_app/models/product.dart';
import 'package:storekeeper_app/providers/product_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // -------------------------------------------------
  // Helper: show delete confirmation dialog
  // -------------------------------------------------
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete product?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storekeeper'),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // Show loading spinner while DB is initializing
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = provider.products;

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final product = products[i];
              return _ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------
// Separate widget for a single product card (easier to test & reuse)
// -----------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

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
        final shouldDelete = await HomeScreen()._confirmDelete(context);
        if (shouldDelete) {
          provider.deleteProduct(product.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted')),
          );
        }
        return false; // we handle delete ourselves
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: ListTile(
          leading: _buildImage(),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Qty: ${product.quantity}  •  \$${product.price.toStringAsFixed(2)}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to Detail (optional) → Edit
            Navigator.pushNamed(
              context,
              '/detail',
              arguments: product,
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.imagePath == null || product.imagePath!.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.inventory_2, color: Colors.grey),
      );
    }

    final file = File(product.imagePath!);
    if (!file.existsSync()) {
      return const CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return CircleAvatar(
      backgroundImage: FileImage(file),
      radius: 24,
    );
  }
}