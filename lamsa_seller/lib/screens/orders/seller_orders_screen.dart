import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_order_service.dart';

// سيُستبدل بنظام العملات لاحقاً
const String _currency = 'ر.س';

enum _Filter { all, pending, active, done, closed }

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final _service = SellerOrderService();
  late final Stream<QuerySnapshot> _stream = _service.streamMyOrders();
  _Filter _filter = _Filter.all;
  final Set<String> _busy = {};

  static const Map<_Filter, String> _filterLabels = {
    _Filter.all: 'الكل',
    _Filter.pending: 'بانتظار الموافقة',
    _Filter.active: 'قيد التنفيذ',
    _Filter.done: 'مكتملة',
    _Filter.closed: 'ملغية ومرفوضة',
  };

  static double _num(dynamic v) => v is num ? v.toDouble() : 0;
  static String? _str(dynamic v) => v is String && v.isNotEmpty ? v : null;
  static String _money(double v) => '${v.toStringAsFixed(0)} $_currency';

  static bool _inFilter(_Filter f, String status) {
    switch (f) {
      case _Filter.all:
        return true;
      case _Filter.pending:
        return status == 'pendingApproval';
      case _Filter.active:
        return status == 'confirmed' || status == 'preparing' || status == 'shipped';
      case _Filter.done:
        return status == 'delivered' || status == 'completed';
      case _Filter.closed:
        return status == 'rejected' || status == 'cancelledByCustomer';
    }
  }

  static (String, Color) _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return ('مؤكد', AppColors.success);
      case 'preparing':
        return ('قيد التجهيز', AppColors.primary);
      case 'shipped':
        return ('تم الشحن', AppColors.accent);
      case 'delivered':
      case 'completed':
        return ('تم التسليم', AppColors.success);
      case 'rejected':
        return ('مرفوض', AppColors.primary);
      case 'cancelledByCustomer':
        return ('ألغاه الزبون', AppColors.grey);
      default:
        return ('بانتظار الموافقة', AppColors.accent);
    }
  }

  static String? _paymentLabel(dynamic type) {
    switch (type) {
      case 'cashOnDelivery':
        return 'الدفع عند الاستلام';
      case 'deposit':
        return 'عربون والباقي عند الاستلام';
      case 'walletTransfer':
        return 'تحويل محفظة';
      case 'fullOnline':
        return 'دفع إلكتروني كامل';
      default:
        return null;
    }
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(String orderId, Map<String, dynamic> data, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(orderId));
    try {
      await _service.updateStatus(
        orderId,
        status,
        customerId: _str(data['customerId']),
        productName: _str(data['productName']),
        productId: _str(data['productId']),
        quantity: data['quantity'] is num ? (data['quantity'] as num).toInt() : null,
      );
    } on FirebaseException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.code == 'permission-denied'
            ? 'تعذّر تحديث الطلب، ربما تغيّرت حالته أو ألغاه الزبون'
            : 'حدث خطأ (${e.code})'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر تحديث الطلب، حاول مرة ثانية')));
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _message(Icons.wifi_off_rounded, 'تعذّر تحميل الطلبات، حاول مرة ثانية');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _message(Icons.receipt_long_outlined, 'ما وصلك أي طلب بعد');

        String statusOf(QueryDocumentSnapshot d) =>
            ((d.data() as Map<String, dynamic>)['status'] ?? 'pendingApproval').toString();
        int count(_Filter f) => docs.where((d) => _inFilter(f, statusOf(d))).length;
        final shown = docs.where((d) => _inFilter(_filter, statusOf(d))).toList();

        return Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                children: _Filter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text('${_filterLabels[f]} (${count(f)})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.primary : AppColors.dark,
                          )),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary.withValues(alpha: 0.14),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selected ? AppColors.primary : AppColors.lightGrey),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? _message(Icons.filter_alt_off_rounded, 'ما فيه طلبات بهذا التصنيف')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.md),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _orderCard(
                        shown[index].id,
                        shown[index].data() as Map<String, dynamic>,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _line(String label, String value, {bool strong = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 14 : 12,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color: color ?? (strong ? AppColors.primary : AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(child: SelectableText(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pendingApproval').toString();
    final (statusText, statusColor) = _statusInfo(status);
    final created = data['createdAt'];
    final date = created is Timestamp ? created.toDate() : null;
    final shortId = orderId.length >= 6 ? orderId.substring(orderId.length - 6) : orderId;
    final total = _num(data['totalAmount']);
    final paid = _num(data['paidAmount']);
    final remaining = _num(data['remainingAmount']);
    final delivery = _num(data['deliveryFee']);
    final qty = data['quantity'] is num ? (data['quantity'] as num).toInt() : 1;
    final payment = _paymentLabel(data['paymentType']);
    final reference = _str(data['transferReference']);
    final hasCoupon = _str(data['couponId']) != null;
    final address = _str(data['customerAddress']);
    final phone = _str(data['customerPhone']);
    final image = (data['productImage'] ?? '').toString();
    final open = status == 'pendingApproval' ||
        status == 'confirmed' ||
        status == 'preparing' ||
        status == 'shipped';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null ? '#$shortId' : '#$shortId  ·  ${date.day}/${date.month}/${date.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText,
                    style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(width: 52, height: 52, color: AppColors.lightGrey),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['productName'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('الكمية: $qty',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _infoLine(Icons.person_outline_rounded, (data['customerName'] ?? '-').toString()),
          if (phone != null) _infoLine(Icons.phone_outlined, phone),
          if (address != null) _infoLine(Icons.location_on_outlined, address),
          const Divider(height: 20),
          if (payment != null) _line('طريقة الدفع', payment),
          if (delivery > 0) _line('رسوم التوصيل', _money(delivery)),
          if (hasCoupon) _line('كود خصم', 'مطبّق'),
          if (paid > 0) _line('المدفوع مسبقاً', _money(paid)),
          _line('الإجمالي', _money(total), strong: true),
          if (remaining > 0 && open)
            _line('يحصّل من الزبون عند التسليم', _money(remaining), color: AppColors.accent),
          if (reference != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ تحقق من التحويل قبل الموافقة، المرجع: $reference',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
            ),
          ],
          if (open) ...[
            const SizedBox(height: 12),
            _actions(orderId, data, status, remaining),
          ],
        ],
      ),
    );
  }

  Widget _actions(String orderId, Map<String, dynamic> data, String status, double remaining) {
    final busy = _busy.contains(orderId);

    Widget full(String label, IconData icon, VoidCallback onTap) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: busy ? null : onTap,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Icon(icon, size: 16),
          label: Text(label),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
        ),
      );
    }

    switch (status) {
      case 'pendingApproval':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await _confirm('رفض الطلب', 'سيصل الزبون إشعار بالرفض. متأكد؟', 'رفض');
                        if (ok && mounted) await _run(orderId, data, 'rejected');
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(42),
                ),
                child: const Text('رفض'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: busy ? null : () => _run(orderId, data, 'confirmed'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('موافقة'),
              ),
            ),
          ],
        );
      case 'confirmed':
        return full('بدء التجهيز', Icons.inventory_2_outlined, () => _run(orderId, data, 'preparing'));
      case 'preparing':
        return full('تم الشحن', Icons.local_shipping_outlined, () => _run(orderId, data, 'shipped'));
      case 'shipped':
        return full('تم التسليم', Icons.home_rounded, () async {
          final body = remaining > 0
              ? 'تأكد أنك استلمت من الزبون المتبقي: ${_money(remaining)}'
              : 'تأكيد تسليم الطلب للزبون.';
          final ok = await _confirm('تأكيد التسليم', body, 'تم التسليم');
          if (ok && mounted) await _run(orderId, data, 'delivered');
        });
      default:
        return const SizedBox.shrink();
    }
  }
}
