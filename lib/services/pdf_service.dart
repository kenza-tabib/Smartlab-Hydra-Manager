import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/report.dart';

class PdfService {
  Future<File> generateReport(Report report) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'SMART LAB',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1565C0'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Rapport de Maintenance',
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                  ),
                  pw.Divider(thickness: 2, color: PdfColor.fromHex('#1565C0')),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            _buildField('Machine', report.machineName),
            _buildField('Date', report.date),
            _buildField('Technicien', report.technician),
            pw.SizedBox(height: 20),
            _buildSection('Description panne', report.failureDescription),
            pw.SizedBox(height: 16),
            _buildSection('Intervention', report.intervention),
            pw.SizedBox(height: 16),
            _buildSection('Résultat', report.result),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Généré le ${dateFormat.format(DateTime.now())} - Smart Lab Hydra Manager',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1565C0'),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(content.isEmpty ? 'N/A' : content),
        ),
      ],
    );
  }

  Future<void> shareReport(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Rapport de maintenance Smart Lab',
      ),
    );
  }
}
