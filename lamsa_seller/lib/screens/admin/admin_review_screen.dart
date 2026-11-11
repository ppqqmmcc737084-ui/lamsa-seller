import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/seller_application_service.dart';

/// شاشة المدير: طلبات التجار بانتظار المراجعة.
class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final _service = SellerApplicationService();
  late final Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _stream = _service.streamPending();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التجار'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذّر تحميل الطلبات'));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(
              child: Text('ما فيه طلبات بانتظار المراجعة', style: TextStyle(color: AppColors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data();
              final submitted = d['submittedAt'];
              final date = submitted is Timestamp ? submitted.toDate() : null;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminApplicationScreen(uid: doc.id, data: d)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((d['storeName'] ?? '').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text('${d['fullName'] ?? ''} · ${d['governorate'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                              if (date != null)
                                Text('${date.day}/${date.month}/${date.year}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminApplicationScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  const AdminApplicationScreen({super.key, required this.uid, required this.data});

  @override
  State<AdminApplicationScreen> createState() => _AdminApplicationScreenState();
}

class _AdminApplicationScreenState extends State<AdminApplicationScreen> {
  final _service = SellerApplicationService();
  final Map<String, Future<String>> _urls = {};
  bool _busy = false;

  Future<String> _urlFor(String path) => _urls.putIfAbsent(path, () => _service.docUrl(path));

  Map<String, dynamic> get _d => widget.data;
  String _v(String key) => (_d[key] ?? '').toString();

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.grey)),
          const SizedBox(width: 12),
          Flexible(
            child: SelectableText(value.isEmpty ? '-' : value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _image(String label, dynamic path) {
    if (path is! String || path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          FutureBuilder<String>(
            future: _urlFor(path),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text('تعذّر تحميل الصورة',
                    style: TextStyle(color: AppColors.primary, fontSize: 12));
              }
              if (!snap.hasData) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              final url = snap.data!;
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(url))),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Image.network(url, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _decide({required bool approve, String? reason}) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await _service.review(widget.uid, approve: approve, reason: reason);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(approve ? 'تم قبول التاجر' : 'تم رفض الطلب')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر تنفيذ القرار، حاول مرة ثانية')));
    }
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قبول التاجر'),
        content: const Text('بعد القبول يقدر التاجر ينشر منتجات. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
    if (ok == true) await _decide(approve: true);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'سبب الرفض (يظهر للتاجر، 5 أحرف على الأقل)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.length >= 5) Navigator.pop(ctx, text);
            },
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (reason != null) await _decide(approve: false, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final passport = _v('idType') == 'passport';
    final fee = _d['deliveryFee'];
    return Scaffold(
      appBar: AppBar(title: Text(_v('storeName').isEmpty ? 'طلب تاجر' : _v('storeName'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('البريد', _v('email')),
                    _row('اسم المتجر', _v('storeName')),
                    _row('الجوال', _v('phone')),
                    _row('العنوان', '${_v('governorate')} - ${_v('address')}'),
                    const Divider(height: 24),
                    _row('الاسم الكامل', _v('fullName')),
                    _row('نوع الوثيقة', passport ? 'جواز سفر' : 'هوية وطنية'),
                    _row('رقم الوثيقة', _v('idNumber')),
                    const Divider(height: 24),
                    _row('رسوم التوصيل', fee is num && fee > 0 ? '$fee ر.ي' : 'مجاني'),
                    _row('المحفظة', _v('walletNumber').isEmpty ? 'لا يوجد' : '${_v('walletName')} - ${_v('walletNumber')}'),
                    const SizedBox(height: 16),
                    _image(passport ? 'صفحة الجواز' : 'وجه الهوية', _d['idFrontPath']),
                    _image('ظهر الهوية', _d['idBackPath']),
                    _image('الصورة الشخصية مع الوثيقة', _d['selfiePath']),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _approve,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('قبول'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
