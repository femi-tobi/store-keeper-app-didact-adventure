import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/product_detail_screen.dart';

void main() {
  runApp(const StorekeeperApp());
}

class StorekeeperApp extends StatelessWidget {
  const StorekeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider()..initDatabase(),
      child: MaterialApp(
        title: 'Storekeeper',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        // ---------- ROUTES ----------
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/add': (_) => const AddProductScreen(),      // const will work after screen is const-constructor
          '/edit': (_) => const EditProductScreen(),
          '/detail': (_) => const ProductDetailScreen(),
        },
      ),
    );
  }
}