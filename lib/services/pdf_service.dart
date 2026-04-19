import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking_model.dart';
import '../models/billing_model.dart';

class PDFService {
  /// Generate and print job completion certificate
  static Future<void> printJobCompletionCertificate({
    required BookingModel booking,
    required String technicianName,
    required int completedJobsCount,
  }) async {
    try {
      final pdf = pw.Document();
      
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
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'JOB COMPLETION CERTIFICATE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Bharat Doorstep Repair Partner',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Job Details
                pw.Text(
                  'Job Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                
                _buildDetailRow('Booking ID:', booking.id),
                _buildDetailRow('Service:', booking.service),
                _buildDetailRow('Customer:', booking.userName),
                _buildDetailRow('Address:', booking.address ?? 'N/A'),
                _buildDetailRow('Scheduled Time:', booking.scheduledTime),
                _buildDetailRow('Completion Date:', DateTime.now().toString().split(' ')[0]),
                
                pw.SizedBox(height: 30),
                
                // Technician Details
                pw.Text(
                  'Technician Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                
                _buildDetailRow('Technician Name:', technicianName),
                _buildDetailRow('Total Jobs Completed:', completedJobsCount.toString()),
                _buildDetailRow('Service Status:', 'COMPLETED ✓'),
                
                pw.SizedBox(height: 40),
                
                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This certificate confirms the successful completion of the above service.',
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Generated on: ${DateTime.now()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Print the certificate
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Job_Completion_Certificate_${booking.id}',
      );
      
    } catch (e) {
      print('Error generating job completion certificate: $e');
      rethrow;
    }
  }

  /// Generate GST compliant invoice PDF
  static Future<void> generateGSTInvoice({
    required BillingModel billing,
    bool downloadToDevice = false,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Load company logo (if available)
      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
      } catch (e) {
        // Logo not found, continue without it
      }
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo and company details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null)
                          pw.Container(
                            width: 80,
                            height: 80,
                            child: pw.Image(pw.MemoryImage(logoBytes)),
                          ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'BHARAT DOORSTEP REPAIR PARTNER',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        'TAX INVOICE (GST)',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Company registered office
                pw.Text(
                  'Registered Office:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Bharat Doorstep Repair Partner'),
                pw.Text('Lucknow, Uttar Pradesh, India'),
                pw.Text('GSTIN: 09XXXXXXXXXX'),
                
                pw.SizedBox(height: 20),
                
                // Invoice details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice Details:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Invoice No: ${billing.invoiceNumber}'),
                        pw.Text('Invoice Date: ${_formatDate(billing.invoiceDate)}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Customer Name: ${billing.customerName}'),
                        pw.Text('Service Address: ${billing.serviceAddress}'),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Service details table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Description', isHeader: true),
                        _buildTableCell('Amount (₹)', isHeader: true),
                      ],
                    ),
                    // Service details
                    pw.TableRow(children: [
                      _buildTableCell('Final Service Charges'),
                      _buildTableCell(billing.servicePrice.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('Coin Discount'),
                      _buildTableCell('-${billing.coinDiscount.toStringAsFixed(2)}'),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('Net Taxable Value'),
                      _buildTableCell(billing.netTaxableValue.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('CGST @9%'),
                      _buildTableCell(billing.cgstAmount.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('SGST @9%'),
                      _buildTableCell(billing.sgstAmount.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('Total GST'),
                      _buildTableCell(billing.totalGst.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('Gross Service Value'),
                      _buildTableCell(billing.grossServiceValue.toStringAsFixed(2)),
                    ]),
                    pw.TableRow(children: [
                      _buildTableCell('Less: Visiting Charge Paid (Adjusted)'),
                      _buildTableCell('-${billing.visitingChargePaid.toStringAsFixed(2)}'),
                    ]),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCell('Balance Payable', isHeader: true),
                        _buildTableCell(billing.balancePayable.toStringAsFixed(2), isHeader: true),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Payment Details Section
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(5),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Information',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Payment Status:'),
                          pw.Text(
                            'PAID',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Payment Method:'),
                          pw.Text(
                            billing.paymentMethod ?? 'Cash',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),
                
                // Important notes
                pw.Text(
                  'Important Notes:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '1. Visiting charge paid at the time of booking has been adjusted against the final service charges.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '2. GST @18% (9% CGST + 9% SGST) is applied on the net taxable value after adjusting visiting charge and coin discount.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '3. GST amount is collected by Bharat Doorstep Repair Partner and remitted to the government.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '4. Coins are loyalty reward points and do not attract GST at the time of earning.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Text(
                  'This is a system-generated invoice and does not require a physical signature.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                
                // Service completion stamp/seal
                pw.Spacer(),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    width: 120,
                    height: 120,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue, width: 3),
                      borderRadius: pw.BorderRadius.circular(60),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'OFFICIAL SEAL',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'BHARAT',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'DOORSTEP',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'REPAIR',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'AUTHORIZED',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Print/share the invoice (works on all platforms)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${billing.invoiceNumber}',
      );
      
    } catch (e) {
      print('Error generating GST invoice: $e');
      rethrow;
    }
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
        textAlign: text.contains('₹') || text.contains('-') || text.contains('.') 
            ? pw.TextAlign.right 
            : pw.TextAlign.left,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Generate job completion certificate (legacy method)
  static Future<void> generateJobCompletionCertificate({
    required BookingModel booking,
    required String technicianName,
    required int completedJobsCount,
  }) async {
    await printJobCompletionCertificate(
      booking: booking,
      technicianName: technicianName,
      completedJobsCount: completedJobsCount,
    );
  }
}