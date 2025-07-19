// lib/features/admin/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح الروابط مثل إثبات الدفع أو الفاتورة
import 'package:printing/printing.dart'; // لتوليد وعرض PDF
import 'package:pdf/pdf.dart'; // لتنسيق PDF
import 'package:pdf/widgets.dart' as pw; // للتعامل مع مكونات PDF

import '../../../core/models/booking_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart'; // سنقوم بإنشاء هذه الخدمة لاحقاً
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/dialogs/confirmation_dialog.dart'; // سنقوم بإنشاء هذا لاحقاً


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
  Future<void> _updateBookingStatus(String newStatus, {String? photographerId}) async {
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
      final notificationService = Provider.of<NotificationService>(context, listen: false); // سنستخدمها هنا

      Map<String, dynamic> updateData = {'status': newStatus};
      if (photographerId != null) {
        updateData['photographerId'] = photographerId;
      }
      await firestoreService.updateBooking(widget.bookingId, updateData);

      // إرسال إشعار للعميل (تنفيذ مبدئي باستخدام NotificationService)
      await notificationService.sendNotificationToUser(
        _booking!.clientId,
        'تحديث الحجز',
        'حالة حجزك لـ "${_booking!.serviceType}" أصبحت: $newStatus',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الحجز إلى: $newStatus')),
      );
      await _fetchBookingDetails(); // إعادة جلب التفاصيل لتحديث الواجهة
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
        const SnackBar(content: Text('لا توجد بيانات حجز لتوليد فاتورة.')),
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
                pw.Text('فاتورة حجز Cam Touch', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text('التكلفة التقديرية:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('\$${_booking!.estimatedCost.toStringAsFixed(2)}'),
                  ],
                ),
                if (_booking!.depositAmount != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('العربون المدفوع:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('\$${_booking!.depositAmount!.toStringAsFixed(2)}'),
                    ],
                  ),
                // يمكنك إضافة المزيد من التفاصيل هنا
              ],
            );
          },
        ),
      );

      // حفظ ملف الـ PDF مؤقتاً وعرضه
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());

      // في تطبيق حقيقي: يمكنك أيضاً تحميل هذا الملف إلى Firebase Storage
      // ثم حفظ رابط URL في حقل `invoiceUrl` في مستند الحجز في Firestore.
      // مثال:
      // final Uint8List pdfBytes = await doc.save();
      // final storageRef = FirebaseStorage.instance.ref().child('invoices/${_booking!.id}.pdf');
      // await storageRef.putData(pdfBytes);
      // final invoiceDownloadUrl = await storageRef.getDownloadURL();
      // await Provider.of<FirestoreService>(context, listen: false).updateBooking(
      //   _booking!.id,
      //   {'invoiceUrl': invoiceDownloadUrl},
      // );
      // _booking = _booking!.copyWith(invoiceUrl: invoiceDownloadUrl); // تحديث النموذج محلياً
    } catch (e) {
      setState(() => _errorMessage = 'فشل توليد أو عرض الفاتورة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // دالة لفتح أي رابط URL (إثبات الدفع أو الفاتورة)
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط المطلوب.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('تفاصيل الحجز')),
        body: const LoadingIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: const Center(child: Text('لا توجد بيانات حجز.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معرف الحجز: ${_booking!.id}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('العميل: ${_booking!.clientName} (${_booking!.clientEmail})', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('الخدمة: ${_booking!.serviceType}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(_booking!.bookingDate)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('الوقت: ${_booking!.bookingTime}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('الموقع: ${_booking!.location}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('التكلفة المقدرة: \$${_booking!.estimatedCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('الحالة: ${_booking!.status}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_booking!.depositAmount != null)
              Text('مبلغ العربون: \$${_booking!.depositAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // الأزرار بناءً على حالة الحجز
            if (_booking!.status == 'pending_admin_approval') ...[
              CustomButton(
                text: 'الموافقة على الحجز',
                onPressed: () => _updateBookingStatus('approved'),
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'رفض الحجز',
                onPressed: () => _updateBookingStatus('rejected'),
                color: Colors.red,
              ),
            ],
            if (_booking!.status == 'approved') ...[
              CustomButton(
                text: 'تأكيد دفع العربون',
                onPressed: () => _updateBookingStatus(
                  'deposit_paid',
                  // هنا يمكن للمدير إدخال مبلغ العربون يدوياً
                  // For now, hardcode or prompt for input
                  // For simplicity, let's assume deposit is 20% of estimated cost
                  // You might want a dialog here for the admin to input the actual deposit amount.
                  // This action should also update the depositAmount field in BookingModel.
                  // Example of updating depositAmount (will require modifying _updateBookingStatus to accept it):
                  // await firestoreService.updateBooking(widget.bookingId, {'status': 'deposit_paid', 'depositAmount': _booking!.estimatedCost * 0.2});
                ),
                color: Colors.blue,
              ),
            ],
            if (_booking!.status == 'deposit_paid' || _booking!.status == 'completed') ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'عرض الفاتورة (PDF)',
                onPressed: () => _generateAndShowInvoice(),
                color: Colors.grey[700],
              ),
              if (_booking!.invoiceUrl != null) ...[
                const SizedBox(height: 8),
                CustomButton(
                  text: 'فتح الفاتورة المحفوظة',
                  onPressed: () => _launchURL(_booking!.invoiceUrl!),
                  color: Colors.teal,
                ),
              ],
            ],
            if (_booking!.paymentProofUrl != null) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'عرض إثبات الدفع',
                onPressed: () => _launchURL(_booking!.paymentProofUrl!),
                color: Colors.purple,
              ),
            ],
            const SizedBox(height: 20),
            // يمكن إضافة زر لتعيين مصور هنا بعد الموافقة
          ],
        ),
      ),
    );
  }
}