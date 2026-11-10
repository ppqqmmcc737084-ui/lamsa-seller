import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_product_service.dart';
import '../../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  String _selectedCategory = 'إلكترونيات';
  final _categories = ['إلكترونيات', 'أزياء', 'منزل', 'جمال', 'رياضة', 'إكسسوارات'];
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();


  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      setState(() => _error = 'الاسم والسعر مطلوبين');
      return;
    }
    if (_imageBytes == null) {
      setState(() => _error = 'لازم تختار صورة للمنتج');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _error = 'السعر لازم يكون رقماً صحيحاً أكبر من صفر');
      return;
    }

    final discountText = _discountController.text.trim();
    final discount = discountText.isEmpty ? null : double.tryParse(discountText);
    if (discountText.isNotEmpty && (discount == null || discount <= 0 || discount >= price)) {
      setState(() => _error = 'سعر العرض لازم يكون رقماً أقل من السعر الأصلي');
      return;
    }

    setState(() {
      _loading = true;
      _uploading = true;
      _error = null;
    });

    try {
      final imageUrl = await StorageService().uploadProductImage(_imageBytes!, _imageName ?? 'product.jpg');
      setState(() => _uploading = false);

      await SellerProductService().addProduct(
        name: name,
        description: desc,
        price: price,
        discountPrice: discount,
        imageUrl: imageUrl,
        category: _selectedCategory,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المنتج بنجاح 🎉')),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر نشر المنتج، حاول مرة ثانية';
        _loading = false;
        _uploading = false;
      });
    }
  }

  String _friendlyError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
      case 'bucket-not-found':
        return 'تعذّر رفع الصورة: التخزين غير مُعدّ في مشروع Firebase (${e.code})';
      case 'unauthorized':
        return 'غير مصرّح لك برفع الصور (${e.code})';
      case 'permission-denied':
        return 'غير مصرّح لك بنشر المنتج، تأكد أن حسابك مفعّل';
      case 'network-request-failed':
      case 'unavailable':
        return 'تحقق من الاتصال بالإنترنت وحاول مرة ثانية';
      default:
        return 'حدث خطأ (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
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
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text('اضغط لاختيار صورة المنتج', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
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
                    ? Text(_uploading ? 'جاري رفع الصورة...' : 'جاري النشر...',
                        style: const TextStyle(color: Colors.white, fontSize: 13))
                    : const Text('نشر المنتج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}