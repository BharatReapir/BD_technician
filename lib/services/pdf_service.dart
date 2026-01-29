import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class PDFService {
  /// Generate invoice PDF for completed booking
  static Future<Uint8List> generateInvoicePDF(BookingModel booking) async {
    final pdf = pw.Document();
    
    // Create invoice content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BHARAT DOORSTEP',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Service Invoice',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice Details',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Invoice ID: ${booking.id.substring(0, 8)}'),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(booking.createdAt)}'),
                      pw.Text('Status: ${booking.status.toUpperCase()}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Customer Details',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Name: ${booking.userName}'),
                      pw.Text('Phone: ${booking.userPhone}'),
                      pw.Text('Address: ${booking.address ?? 'N/A'}'),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Service Details Table
              pw.Text(
                'Service Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Service',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Scheduled Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Service row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.service),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.scheduledTime),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '₹${booking.serviceCharge.toStringAsFixed(0)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Payment Breakdown
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Service Charge:'),
                        pw.Text('₹${booking.serviceCharge.toStringAsFixed(0)}'),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Visiting Charge:'),
                        pw.Text('₹${booking.visitingCharge.toStringAsFixed(0)}'),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('GST (18%):'),
                        pw.Text('₹${booking.gstAmount.toStringAsFixed(0)}'),
                      ],
                    ),
                    if (booking.coinsUsed != null && booking.coinsUsed! > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Coins Discount:'),
                          pw.Text('-₹${booking.coinDiscount?.toStringAsFixed(0) ?? '0'}'),
                        ],
                      ),
                    ],
                    pw.Divider(thickness: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '₹${booking.totalAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Technician Details (if assigned)
              if (booking.technicianName != null) ...[
                pw.Text(
                  'Technician Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Technician: ${booking.technicianName}'),
                pw.Text('Technician ID: ${booking.technicianId?.substring(0, 8) ?? 'N/A'}'),
                pw.SizedBox(height: 20),
              ],
              
              // Footer
              pw.Spacer(),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for choosing Bharat Doorstep!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'For support, contact us at support@bharatdoorstep.com',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  /// Share or download the PDF invoice
  static Future<void> shareInvoicePDF(BookingModel booking) async {
    try {
      final pdfData = await generateInvoicePDF(booking);
      
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'invoice_${booking.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      print('❌ Error sharing PDF: $e');
      rethrow;
    }
  }
  
  /// Print the PDF invoice
  static Future<void> printInvoicePDF(BookingModel booking) async {
    try {
      final pdfData = await generateInvoicePDF(booking);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      print('❌ Error printing PDF: $e');
      rethrow;
    }
  }
}