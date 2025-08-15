// lib/features/admin/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/booking_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/dialogs/confirmation_dialog.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../../core/utils/status_utils.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _booking = await firestoreService.getBooking(widget.bookingId);
      if (_booking == null) {
        _errorMessage = 'لم يتم العثور على تفاصيل الحجز.';
      }
    } catch (e) {
      _errorMessage = 'خطأ أثناء جلب تفاصيل الحجز: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتحديث حالة الحجز
  Future<void> _updateBookingStatus(String newStatus,
      {String? photographerId, Map<String, dynamic>? extraData}) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'تأكيد الإجراء',
        content: 'هل أنت متأكد من تغيير حالة الحجز إلى "$newStatus"؟',
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);

      Map<String, dynamic> updateData = {'status': newStatus};
      if (photographerId != null) {
        updateData['photographerId'] = photographerId;
      }
      if (extraData != null) {
        updateData.addAll(extraData);
      }
      await firestoreService.updateBooking(widget.bookingId, updateData);

      if (newStatus == 'completed') {
        final ids = _booking!.photographerIds ??
            (_booking!.photographerId != null
                ? [_booking!.photographerId!]
                : <String>[]);
        for (final pid in ids) {
          await firestoreService.incrementPhotographerTotalBookings(pid);
        }
      }

      await notificationService.sendNotificationToUser(
        _booking!.clientId,
        'تحديث الحجز',
        'حالة حجزك لـ "${_booking!.serviceType}" أصبحت: $newStatus',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الحجز إلى: $newStatus'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchBookingDetails();
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحديث حالة الحجز: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتوليد وعرض الفاتورة كـ PDF
  Future<void> _generateAndShowInvoice() async {
    if (_booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات حجز لتوليد فاتورة.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('فاتورة حجز كام تاتش', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('رقم الحجز: ${_booking!.id}'),
                pw.Text('تاريخ الحجز: ${DateFormat('yyyy-MM-dd').format(_booking!.bookingDate)}'),
                pw.Text('الخدمة: ${_booking!.serviceType}'),
                pw.Text('العميل: ${_booking!.clientName} (${_booking!.clientEmail})'),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تكلفة الحجز:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${_booking!.estimatedCost.toStringAsFixed(2)} ريال يمني'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المدفوع:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${_booking!.paidAmount.toStringAsFixed(2)} ريال يمني'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المتبقي:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${(_booking!.estimatedCost - _booking!.paidAmount).toStringAsFixed(2)} ريال يمني'),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
    } catch (e) {
      setState(() => _errorMessage = 'فشل توليد أو عرض الفاتورة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // دالة لفتح أي رابط URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الرابط المطلوب.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // إدخال التكلفة عند الموافقة
  Future<void> _approveWithCost() async {
    final controller = TextEditingController();
    final cost = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('أدخل تكلفة الحجز', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'التكلفة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (cost != null) {
      await _updateBookingStatus('approved', extraData: {'estimatedCost': cost});
    }
  }

  // تسجيل العربون
  Future<void> _recordDeposit() async {
    final controller = TextEditingController();
    final deposit = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مبلغ العربون المدفوع', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (deposit != null) {
      await _updateBookingStatus('deposit_paid', extraData: {
        'depositAmount': deposit,
        'paidAmount': deposit,
      });
    }
  }

  // تسجيل المبلغ المتبقي
  Future<void> _recordRemainingPayment() async {
    final remaining = _booking!.estimatedCost - _booking!.paidAmount;
    final controller = TextEditingController(text: remaining.toString());
    final paid = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('دفع المبلغ المتبقي', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (paid != null) {
      final total = _booking!.paidAmount + paid;
      await _updateBookingStatus('completed', extraData: {
        'paidAmount': total,
      });
    }
  }

  // تعديل تكلفة الحجز
  Future<void> _editCost() async {
    final controller = TextEditingController(text: _booking!.estimatedCost.toString());
    final newCost = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل تكلفة الحجز', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'التكلفة الجديدة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (newCost != null) {
      setState(() => _isLoading = true);
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.updateBooking(widget.bookingId, {'estimatedCost': newCost});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث تكلفة الحجز'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchBookingDetails();
      } catch (e) {
        setState(() {
          _errorMessage = 'فشل تحديث التكلفة: $e';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // بناء بطاقة المعلومات
  Widget _buildInfoCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة الحالة
  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_booking!.status);
    final statusLabel = getBookingStatusLabel(_booking!.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(_booking!.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الحجز',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة المالية
  Widget _buildFinancialCard() {
    final remaining = _booking!.estimatedCost - _booking!.paidAmount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'المعلومات المالية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFinancialItem(
                  'التكلفة الإجمالية',
                  '${_booking!.estimatedCost.toStringAsFixed(2)} ريال',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildFinancialItem(
                  'المدفوع',
                  '${_booking!.paidAmount.toStringAsFixed(2)} ريال',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildFinancialItem(
                  'المتبقي',
                  '${remaining.toStringAsFixed(2)} ريال',
                  remaining > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          if (_booking!.depositAmount != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    'مبلغ العربون: ${_booking!.depositAmount!.toStringAsFixed(2)} ريال',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // بناء قسم الأزرار
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات الحجز',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_booking!.status == 'pending_admin_approval') ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'الموافقة على الحجز',
                    onPressed: _approveWithCost,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'رفض الحجز',
                    onPressed: () => _updateBookingStatus('rejected'),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
          if (_booking!.status == 'approved' || _booking!.status == 'scheduled') ...[
            CustomButton(
              text: 'تسجيل دفع العربون',
              onPressed: _recordDeposit,
              color: Colors.blue,
            ),
          ],
          if (_booking!.status == 'deposit_paid' && _booking!.paidAmount < _booking!.estimatedCost) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'تسديد المتبقي',
              onPressed: _recordRemainingPayment,
              color: Colors.orange,
            ),
          ],
          if (_booking!.estimatedCost > 0) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'تعديل التكلفة',
              onPressed: _editCost,
              color: Colors.blueGrey,
            ),
          ],
        ],
      ),
    );
  }

  // بناء قسم الملفات
  Widget _buildFilesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الملفات والوثائق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_booking!.status == 'deposit_paid' || _booking!.status == 'completed') ...[
            CustomButton(
              text: 'عرض الفاتورة (PDF)',
              onPressed: _generateAndShowInvoice,
              color: Colors.grey[700]!,
            ),
            if (_booking!.invoiceUrl != null) ...[
              const SizedBox(height: 12),
              CustomButton(
                text: 'فتح الفاتورة المحفوظة',
                onPressed: () => _launchURL(_booking!.invoiceUrl!),
                color: Colors.teal,
              ),
            ],
          ],
          if (_booking!.paymentProofUrl != null) ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'عرض إثبات الدفع',
              onPressed: () => _launchURL(_booking!.paymentProofUrl!),
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'scheduled':
        return Colors.indigo;
      case 'deposit_paid':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'deposit_paid':
        return Icons.payment;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'تفاصيل الحجز'),
        body: const LoadingIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'تفاصيل الحجز'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchBookingDetails,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'تفاصيل الحجز'),
        body: const Center(
          child: Text('لا توجد بيانات حجز.'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'تفاصيل الحجز'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الحالة
              _buildStatusCard(),
              
              // بطاقة المعلومات الأساسية
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'معلومات الحجز',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard('رقم الحجز', _booking!.id, Icons.confirmation_number, color: Colors.blue),
                    _buildInfoCard('اسم العميل', _booking!.clientName, Icons.person, color: Colors.green),
                    _buildInfoCard('البريد الإلكتروني', _booking!.clientEmail, Icons.email, color: Colors.orange),
                    _buildInfoCard('نوع الخدمة', _booking!.serviceType, Icons.camera_alt, color: Colors.purple),
                    _buildInfoCard('التاريخ', DateFormat('yyyy-MM-dd').format(_booking!.bookingDate), Icons.calendar_today, color: Colors.indigo),
                    _buildInfoCard('الوقت', _booking!.bookingTime, Icons.access_time, color: Colors.teal),
                    _buildInfoCard('الموقع', _booking!.location, Icons.location_on, color: Colors.red),
                  ],
                ),
              ),
              
              // بطاقة المعلومات المالية
              _buildFinancialCard(),
              
              // قسم الأزرار
              _buildActionButtons(),
              
              // قسم الملفات
              _buildFilesSection(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}