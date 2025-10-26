import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late TextEditingController _priceController;

  File? _selectedImage;
  String? _existingImagePath;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final product = ModalRoute.of(context)!.settings.arguments as Product?;

    if (product != null) {
      _nameController = TextEditingController(text: product.name);
      _descriptionController = TextEditingController(text: product.description);
      _stockController = TextEditingController(text: product.stock.toString());
      _priceController = TextEditingController(text: product.price.toStringAsFixed(2));
      _existingImagePath = product.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _copyImageToAppDir(File source) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(source.path);
    var savedFile = File('${appDir.path}/$fileName');

    if (await savedFile.exists()) {
      final ext = p.extension(fileName);
      final name = p.basenameWithoutExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newName = '${name}_$timestamp$ext';
      savedFile = File('${appDir.path}/$newName');
    }

    await source.copy(savedFile.path);
    return savedFile.path;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? newImagePath = _existingImagePath;

      if (_selectedImage != null) {
        newImagePath = await _copyImageToAppDir(_selectedImage!);
        if (_existingImagePath != null && _existingImagePath != newImagePath) {
          final oldFile = File(_existingImagePath!);
          if (await oldFile.exists()) await oldFile.delete();
        }
      }

      final product = ModalRoute.of(context)!.settings.arguments as Product;
      final updatedProduct = product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        stock: int.parse(_stockController.text),
        price: double.parse(_priceController.text),
        imagePath: newImagePath,
      );

      await Provider.of<ProductProvider>(context, listen: false)
          .updateProduct(updatedProduct);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProduct() async {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Product?'),
            content: Text('Are you sure you want to delete "${product.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      if (product.imagePath != null && product.imagePath!.isNotEmpty) {
        final file = File(product.imagePath!);
        if (await file.exists()) await file.delete();
      }

      await Provider.of<ProductProvider>(context, listen: false)
          .deleteProduct(product.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product?;

    if (product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : _existingImagePath != null && _existingImagePath!.isNotEmpty
                                ? DecorationImage(image: FileImage(File(_existingImagePath!)), fit: BoxFit.cover)
                                : null,
                      ),
                      child: _selectedImage == null && (_existingImagePath == null || _existingImagePath!.isEmpty)
                          ? const Icon(Icons.inventory_2, size: 48, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'camera') _pickImage(ImageSource.camera);
                          if (value == 'gallery') _pickImage(ImageSource.gallery);
                          if (value == 'remove') {
                            setState(() {
                              _selectedImage = null;
                              _existingImagePath = null;
                            });
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'camera', child: Row(children: [Icon(Icons.camera_alt), SizedBox(width: 8), Text('Camera')])),
                          const PopupMenuItem(value: 'gallery', child: Row(children: [Icon(Icons.photo_library), SizedBox(width: 8), Text('Gallery')])),
                          if (_existingImagePath != null || _selectedImage != null)
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Remove Image', style: TextStyle(color: Colors.red))]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter stock';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Enter valid number > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter price';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter valid price > 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _isDeleting ? null : _deleteProduct,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isDeleting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red))
                    : const Text('Delete Product', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}