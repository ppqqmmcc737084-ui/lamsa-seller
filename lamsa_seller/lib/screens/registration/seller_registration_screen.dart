import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/seller_application_service.dart';

const List<String> _governorates = [
  'أمانة العاصمة', 'صنعاء', 'عدن', 'تعز', 'إب', 'الحديدة', 'حضرموت', 'ذمار', 'مأرب', 'البيضاء', 'لحج',
  'أبين', 'شبوة', 'المهرة', 'حجة', 'عمران', 'صعدة', 'الجوف', 'المحويت', 'ريمة', 'الضالع', 'سقطرى',
];
const List<String> _walletOptions = ['الكريمي', 'شلن', 'جوالي', 'أخرى'];

/// تسجيل التاجر على خمس مراحل، كل مرحلة تُحفظ ويكمل من حيث وقف.
class SellerRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> initial;
  const SellerRegistrationScreen({super.key, required this.initial});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  static const _titles = ['البريد', 'المتجر', 'الهوية', 'المحفظة والتوصيل', 'المراجعة'];

  final _service = SellerApplicationService();
  Map<String, dynamic> get _init => widget.initial;
  String _s(String key) => (_init[key] ?? '').toString();

  static String _feeText(dynamic v) {
    if (v is num && v > 0) return v % 1 == 0 ? v.toInt().toString() : v.toString();
    return '';
  }

  late int _step = (((_init['step'] ?? 0) as num).toInt()).clamp(0, 4).toInt();
  late final _storeName = TextEditingController(text: _s('storeName'));
  late final _phone = TextEditingController(text: _s('phone'));
  late final _address = TextEditingController(text: _s('address'));
  late final _fullName = TextEditingController(text: _s('fullName'));
  late final _idNumber = TextEditingController(text: _s('idNumber'));
  late final _walletNumber = TextEditingController(text: _s('walletNumber'));
  late final _deliveryFee = TextEditingController(text: _feeText(_init['deliveryFee']));
  late String? _governorate = _governorates.contains(_s('governorate')) ? _s('governorate') : null;
  late String _idType = _s('idType') == 'passport' ? 'passport' : 'national';
  late String _walletName = _walletOptions.contains(_s('walletName')) ? _s('walletName') : _walletOptions.first;
  late bool _terms = _init['acceptedTerms'] == true;

  late final Map<String, String?> _paths = {
    'idFront': _init['idFrontPath'] as String?,
    'idBack': _init['idBackPath'] as String?,
    'selfie': _init['selfiePath'] as String?,
  };
  final Map<String, Uint8List> _local = {};

  bool _busy = false;
  String? _error;

  bool get _verified => FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  @override
  void dispose() {
    _storeName.dispose();
    _phone.dispose();
    _address.dispose();
    _fullName.dispose();
    _idNumber.dispose();
    _walletNumber.dispose();
    _deliveryFee.dispose();
    super.dispose();
  }

  String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
      case 'bucket-not-found':
        return 'التخزين غير مُعدّ في مشروع Firebase بعد (${e.code})';
      case 'unauthorized':
      case 'permission-denied':
        return 'غير مصرّح بهذه العملية (${e.code}). تأكد من نشر القواعد الجديدة';
      case 'network-request-failed':
      case 'unavailable':
        return 'تحقق من الاتصال بالإنترنت وحاول مرة ثانية';
      default:
        return 'حدث خطأ (${e.code})';
    }
  }

  Future<void> _resend() async {
    await AuthService().sendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أُرسل رابط التفعيل، افحص بريدك ومجلد الرسائل غير المرغوبة')),
    );
  }

  Future<void> _refreshVerification() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!_verified) _error = 'لم يتم تفعيل البريد بعد، افتح الرابط في رسالتنا ثم اضغط تحديث';
    });
  }

  String _fieldOf(String slot) => '${slot}Path';

  Future<void> _pick(String slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1800);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 4 * 1024 * 1024) {
        if (mounted) setState(() => _error = 'الصورة كبيرة، اختر صورة أصغر من 4 ميجا');
        return;
      }
      if (mounted) {
        setState(() {
          _busy = true;
          _error = null;
        });
      }
      final path = await _service.uploadDoc(bytes, slot, picked.name);
      await _service.saveFields({_fieldOf(slot): path});
      if (!mounted) return;
      setState(() {
        _local[slot] = bytes;
        _paths[slot] = path;
        _busy = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendly(e);
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر رفع الصورة، حاول مرة ثانية';
        _busy = false;
      });
    }
  }

  String? _validate(int step) {
    switch (step) {
      case 0:
        return _verified ? null : 'فعّل بريدك الإلكتروني أولاً (افتح الرابط في رسالتنا ثم اضغط تحديث)';
      case 1:
        if (_storeName.text.trim().length < 3) return 'اسم المتجر لازم 3 أحرف على الأقل';
        if (!RegExp(r'^\+?\d{9,15}$').hasMatch(_phone.text.trim())) return 'رقم الجوال غير صحيح (أرقام فقط)';
        if (_governorate == null) return 'اختر المحافظة';
        if (_address.text.trim().length < 5) return 'اكتب عنوان المتجر بوضوح';
        return null;
      case 2:
        if (_fullName.text.trim().split(RegExp(r'\s+')).length < 2) {
          return 'اكتب اسمك الكامل كما في الوثيقة (اسمان على الأقل)';
        }
        if (_idNumber.text.trim().length < 5) return 'رقم الهوية أو الجواز غير صحيح';
        if (_paths['idFront'] == null) {
          return _idType == 'passport' ? 'ارفع صورة صفحة الجواز' : 'ارفع صورة وجه الهوية';
        }
        if (_idType == 'national' && _paths['idBack'] == null) return 'ارفع صورة ظهر الهوية';
        if (_paths['selfie'] == null) return 'ارفع صورتك وأنت ماسك الوثيقة';
        return null;
      case 3:
        {
          final feeText = _deliveryFee.text.trim();
          if (feeText.isNotEmpty) {
            final fee = double.tryParse(feeText);
            if (fee == null || fee < 0) return 'رسوم التوصيل لازم تكون رقماً';
          }
          final wallet = _walletNumber.text.trim();
          if (wallet.isNotEmpty && !RegExp(r'^\d{6,15}$').hasMatch(wallet)) {
            return 'رقم المحفظة غير صحيح (أرقام فقط)';
          }
          return null;
        }
      default:
        return null;
    }
  }

  Map<String, dynamic> _payload(int step) {
    switch (step) {
      case 1:
        return {
          'storeName': _storeName.text.trim(),
          'phone': _phone.text.trim(),
          'governorate': _governorate,
          'address': _address.text.trim(),
        };
      case 2:
        return {
          'fullName': _fullName.text.trim(),
          'idType': _idType,
          'idNumber': _idNumber.text.trim(),
          if (_idType == 'passport') 'idBackPath': null,
        };
      case 3:
        {
          final wallet = _walletNumber.text.trim();
          return {
            'walletName': wallet.isEmpty ? null : _walletName,
            'walletNumber': wallet.isEmpty ? null : wallet,
            'deliveryFee': double.tryParse(_deliveryFee.text.trim()) ?? 0,
          };
        }
      default:
        return {};
    }
  }

  Future<void> _next() async {
    final problem = _validate(_step);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.saveFields(_payload(_step), step: _step + 1);
      if (!mounted) return;
      setState(() {
        _step += 1;
        _busy = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendly(e);
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر حفظ البيانات، حاول مرة ثانية';
        _busy = false;
      });
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_terms) {
      setState(() => _error = 'لازم توافق على الشروط لإرسال الطلب');
      return;
    }
    for (final s in [0, 1, 2, 3]) {
      final problem = _validate(s);
      if (problem != null) {
        setState(() {
          _step = s;
          _error = problem;
        });
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.saveFields({..._payload(3), 'acceptedTerms': true}, step: 4);
      final problem = await _service.submit();
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (problem != null) _error = problem;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendly(e);
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر إرسال الطلب، حاول مرة ثانية';
        _busy = false;
      });
    }
  }

  // ===== الواجهة =====

  Widget _info(String text) =>
      Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.grey, height: 1.6));

  Widget _field(TextEditingController c, String hint, {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.grey)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(String slot, String label) {
    final bytes = _local[slot];
    final uploaded = _paths[slot] != null;
    return GestureDetector(
      onTap: _busy ? null : () => _pick(slot),
      child: Container(
        height: 120,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: uploaded ? AppColors.success : AppColors.lightGrey, width: 1.5),
          image: bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null,
        ),
        child: bytes != null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    uploaded ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                    color: uploaded ? AppColors.success : AppColors.grey,
                    size: 30,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uploaded ? '$label (تم الرفع، اضغط للتغيير)' : label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stepEmail() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final color = _verified ? AppColors.success : AppColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info('نتأكد أن بريدك يخصك قبل أي خطوة. أرسلنا رابط تفعيل إلى:'),
        const SizedBox(height: 8),
        Text(email, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(_verified ? Icons.verified_rounded : Icons.mark_email_unread_outlined, color: color),
            const SizedBox(width: 8),
            Text(_verified ? 'تم تفعيل البريد' : 'البريد غير مفعّل بعد',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        if (!_verified) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _resend,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  child: const Text('إعادة إرسال الرابط'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _refreshVerification,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  child: const Text('تحديث'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stepStore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_storeName, 'اسم المتجر'),
        _field(_phone, 'رقم جوال المتجر', type: TextInputType.phone),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _governorate,
            hint: const Text('المحافظة'),
            items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (value) => setState(() => _governorate = value),
          ),
        ),
        _field(_address, 'العنوان (المديرية، الحي، أقرب معلم)', maxLines: 2),
      ],
    );
  }

  Widget _stepIdentity() {
    final passport = _idType == 'passport';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info('صور الوثائق تُرفع إلى مسار خاص ولا يراها إلا فريق المراجعة.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('هوية وطنية'),
              selected: !passport,
              onSelected: (_) => setState(() => _idType = 'national'),
            ),
            ChoiceChip(
              label: const Text('جواز سفر'),
              selected: passport,
              onSelected: (_) => setState(() => _idType = 'passport'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field(_fullName, 'الاسم الكامل كما في الوثيقة'),
        _field(_idNumber, passport ? 'رقم الجواز' : 'رقم الهوية'),
        _imageTile('idFront', passport ? 'صورة صفحة الجواز' : 'صورة وجه الهوية'),
        if (!passport) _imageTile('idBack', 'صورة ظهر الهوية'),
        _imageTile('selfie', 'صورتك وأنت ماسك الوثيقة'),
      ],
    );
  }

  Widget _stepWallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_deliveryFee, 'رسوم التوصيل (ر.ي) — اتركه فاضي إذا مجاني', type: TextInputType.number),
        const Text('محفظة إلكترونية لاستلام التحويلات (اختياري)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _walletName,
            items: _walletOptions.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (value) => setState(() => _walletName = value ?? _walletName),
          ),
        ),
        _field(_walletNumber, 'رقم المحفظة (اتركه فاضي إذا ما تستخدمها)', type: TextInputType.phone),
      ],
    );
  }

  Widget _stepReview() {
    final fee = _deliveryFee.text.trim();
    final wallet = _walletNumber.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info('راجع بياناتك قبل الإرسال. بعد الإرسال لا تقدر تعدّلها حتى نرد عليك.'),
        const SizedBox(height: 12),
        _summaryRow('البريد', FirebaseAuth.instance.currentUser?.email ?? ''),
        _summaryRow('اسم المتجر', _storeName.text.trim()),
        _summaryRow('الجوال', _phone.text.trim()),
        _summaryRow('العنوان', '${_governorate ?? ''} - ${_address.text.trim()}'),
        _summaryRow('الاسم الكامل', _fullName.text.trim()),
        _summaryRow('نوع الوثيقة', _idType == 'passport' ? 'جواز سفر' : 'هوية وطنية'),
        _summaryRow('رقم الوثيقة', _idNumber.text.trim()),
        _summaryRow('رسوم التوصيل', fee.isEmpty ? 'مجاني' : '$fee ر.ي'),
        _summaryRow('المحفظة', wallet.isEmpty ? 'لا يوجد' : '$_walletName - $wallet'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(AppRadius.medium)),
          child: const Text(
            'شروط البيع (نص مبدئي يراجعه مختص قانوني قبل الإطلاق):\n'
            '1. بياناتي وصور وثائقي صحيحة وتخصني.\n'
            '2. أبيع منتجات أصلية ومطابقة لوصفها، ولا أبيع ممنوعات.\n'
            '3. ألتزم بتجهيز الطلبات المقبولة وتسليمها في وقتها.\n'
            '4. من حق المنصة إيقاف حسابي عند المخالفة.',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
        ),
        CheckboxListTile(
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('أوافق على الشروط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _content() {
    switch (_step) {
      case 0:
        return _stepEmail();
      case 1:
        return _stepStore();
      case 2:
        return _stepIdentity();
      case 3:
        return _stepWallet();
      default:
        return _stepReview();
    }
  }

  Widget _bottomBar() {
    final last = _step == _titles.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _back,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('السابق'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _busy ? null : (last ? _submit : _next),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(last ? 'إرسال الطلب للمراجعة' : 'التالي'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل متجر جديد'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _busy ? null : () => AuthService().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / _titles.length,
              minHeight: 4,
              color: AppColors.primary,
              backgroundColor: AppColors.lightGrey,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'المرحلة ${_step + 1} من ${_titles.length}: ${_titles[_step]}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((_init['rejectionReason'] ?? '').toString().isNotEmpty && _init['status'] != 'approved') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Text('سبب الرفض السابق: ${_init['rejectionReason']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                    _content(),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }
}
