import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'appointment_store.dart';
import 'seizure_log_store.dart';

class HealthReportExportService {
  HealthReportExportService._();

  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  static Future<void> shareCsv({
    required List<SeizureLog> logs,
    required List<DoctorAppointment> appointments,
  }) async {
    final csv = _buildCsv(logs: logs, appointments: appointments);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    await SharePlus.instance.share(
      ShareParams(
        title: 'Epilepsi takip CSV raporu',
        subject: 'Epilepsi takip CSV raporu',
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/csv',
            name: 'epilepsi_raporu.csv',
          ),
        ],
        fileNameOverrides: ['epilepsi_raporu.csv'],
      ),
    );
  }

  static Future<void> sharePdf({
    required List<SeizureLog> logs,
    required List<DoctorAppointment> appointments,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          pw.Text(
            'Epilepsi Takip Raporu',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Olusturulma: ${_dateTimeFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Nobet Ozeti',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Tarih', 'Tur', 'Sure', 'Tetikleyiciler', 'Not'],
            data: logs
                .map(
                  (log) => [
                    _dateTimeFormat.format(log.occurredAt),
                    _pdfText(log.type),
                    log.durationMinutes == 0
                        ? '-'
                        : '${log.durationMinutes} dk',
                    _pdfText(log.triggerLabel),
                    log.notes.isEmpty ? '-' : _pdfText(log.notes),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Doktor Randevulari',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Tarih', 'Doktor', 'Klinik', 'Not'],
            data: appointments
                .map(
                  (appointment) => [
                    _dateTimeFormat.format(appointment.dateTime),
                    _pdfText(appointment.doctorName),
                    appointment.clinicName.isEmpty
                        ? '-'
                        : _pdfText(appointment.clinicName),
                    appointment.notes.isEmpty
                        ? '-'
                        : _pdfText(appointment.notes),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'epilepsi_raporu.pdf',
    );
  }

  static String _buildCsv({
    required List<SeizureLog> logs,
    required List<DoctorAppointment> appointments,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Nobet Kayitlari');
    buffer.writeln('Tarih,Tur,Sure Dakika,Tetikleyiciler,Not');
    for (final log in logs) {
      buffer.writeln(
        [
          _dateTimeFormat.format(log.occurredAt),
          log.type,
          log.durationMinutes.toString(),
          log.triggerLabel,
          log.notes,
        ].map(_csvCell).join(','),
      );
    }

    buffer.writeln();
    buffer.writeln('Doktor Randevulari');
    buffer.writeln('Tarih,Doktor,Klinik,Not');
    for (final appointment in appointments) {
      buffer.writeln(
        [
          _dateTimeFormat.format(appointment.dateTime),
          appointment.doctorName,
          appointment.clinicName,
          appointment.notes,
        ].map(_csvCell).join(','),
      );
    }

    return buffer.toString();
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _pdfText(String value) {
    return value
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U');
  }
}
