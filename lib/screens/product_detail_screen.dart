import 'dart:io'; // <-- ADD THIS LINE

import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Product? product =
        ModalRoute.of(context)!.settings.arguments as Product?;

    return Scaffold(
      appBar: AppBar(title: Text(product?.name ?? 'Detail')),
      body: Center(
        child: product == null
            ? const Text('No product data')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product.imagePath != null && product.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(product.imagePath!),
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2, size: 50),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Quantity: ${product.quantity}'),
                  Text('Price: \$${product.price.toStringAsFixed(2)}'),
                ],
              ),
      ),
    );
  }
}