import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_product_service.dart';
import '../../services/storage_service.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;
  const EditProductScreen({super.key, required this.productId, required this.data});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final _nameController = TextEditingController(text: widget.data['name'] ?? '');
  late final _descController = TextEditingController(text: widget.data['description'] ?? '');
  late final _priceController = TextEditingController(text: '${widget.data['price'] ?? ''}');
  late final _discountController = TextEditingController(
      text: widget.data['discountPrice'] != null ? '${widget.data['discountPrice']}' : '');

  late String _selectedCategory = widget.data['category'] ?? 'إلكترونيات';
  final _categories = ['إلكترونيات', 'أزياء', 'منزل', 'جمال', 'رياضة', 'إكسسوارات'];

  Uint8List? _newImageBytes;
  String? _newImageName;
  late String _currentImageUrl = widget.data['imageUrl'] ?? '';

  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _newImageBytes = bytes;
      _newImageName = picked.name;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) {
      setState(() => _error = 'الاسم والسعر مطلوبين');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null) {
      setState(() => _error = 'السعر لازم يكون رقم صحيح');
      return;
    }
    final discountText = _discountController.text.trim();
    final discount = discountText.isEmpty ? null : double.tryParse(discountText);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String imageUrl = _currentImageUrl;
      if (_newImageBytes != null) {
        imageUrl = await StorageService().uploadProductImage(_newImageBytes!, _newImageName ?? 'product.jpg');
      }

      await SellerProductService().updateProduct(
        widget.productId,
        name: name,
        description: _descController.text.trim(),
        price: price,
        discountPrice: discount,
        imageUrl: imageUrl,
        category: _selectedCategory,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المنتج بنجاح ✅')),
      );
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المنتج')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  image: _newImageBytes != null
                      ? DecorationImage(image: MemoryImage(_newImageBytes!), fit: BoxFit.cover)
                      : (_currentImageUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(_currentImageUrl), fit: BoxFit.cover)
                          : null),
                ),
                child: (_newImageBytes == null && _currentImageUrl.isEmpty)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text('اضغط لاختيار صورة المنتج', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'اسم المنتج')),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(hintText: 'وصف المنتج')),
            const SizedBox(height: 12),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'السعر (ر.س)')),
            const SizedBox(height: 12),
            TextField(controller: _discountController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'سعر العرض (اختياري)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}