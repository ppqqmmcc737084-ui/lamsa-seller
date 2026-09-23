import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_banner_service.dart';
import '../../services/seller_product_service.dart';

class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  final _titleController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  String? _selectedProductId;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _titleController.text.trim().isEmpty) {
      setState(() => _error = 'الصورة والعنوان مطلوبين');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SellerBannerService().addBanner(
        imageBytes: _imageBytes!,
        imageName: _imageName ?? 'banner.jpg',
        title: _titleController.text.trim(),
        productId: _selectedProductId,
      );
      if (!mounted) return;
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('إضافة بانر ترويجي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null,
                ),
                child: _imageBytes == null
                    ? const Center(
                        child: Text('اضغط لاختيار صورة البانر (أفقية يفضل)', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'عنوان العرض (مثل: خصم 30%)')),
            const SizedBox(height: 16),
            const Text('اربط البانر بمنتج (اختياري)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: SellerProductService().streamMyProducts(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(hintText: 'بدون ربط'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون ربط')),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? ''));
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedProductId = value),
                );
              },
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
                    : const Text('نشر البانر'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}