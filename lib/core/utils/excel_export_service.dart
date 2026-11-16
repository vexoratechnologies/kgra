import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/payment/data/models/payment_model.dart';
import 'committee_helper.dart';
import 'file_download_helper.dart';

/// ExcelExportService provides structured, styled .xlsx spreadsheet generation
/// and instant cross-platform file download/sharing for KGRA admin operations.
class ExcelExportService {
  ExcelExportService._();

  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFmt = DateFormat('dd/MM/yyyy hh:mm a');

  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF1B365D'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// Helper to style all header cells of a sheet
  static void _applyHeaderStyle(Sheet sheet, int columnCount) {
    for (int col = 0; col < columnCount; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = _headerStyle;
    }
  }

  // ==========================================
  // 1. Export All Members / Filtered Members
  // ==========================================

  static Future<String?> exportMembers({
    required List<UserModel> members,
    String sheetTitle = 'Members',
    String? customFileName,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetTitle);
    final sheet = excel[sheetTitle];

    final headers = [
      'Sl No',
      'Membership ID',
      'Full Name',
      'Phone Number',
      'Zone',
      'Primary Designation',
      'All Designations',
      'Institution / Workplace',
      'Status',
      'Date of Birth',
      'Date of Joining',
      'Date of Retirement',
      'State Committee Role',
      'Executive Committee Role',
      'Zonal Committee Role',
      'Registered Date',
      'Reviewed By',
      'Reviewed Date',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _applyHeaderStyle(sheet, headers.length);

    // Column widths
    final widths = [
      8.0,
      18.0,
      24.0,
      16.0,
      18.0,
      24.0,
      30.0,
      28.0,
      14.0,
      14.0,
      14.0,
      14.0,
      22.0,
      24.0,
      22.0,
      16.0,
      20.0,
      16.0,
    ];
    for (int i = 0; i < widths.length && i < headers.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

    // Rows
    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final regDate = _dateFmt.format(m.createdAt);
      final allDes = m.allDesignations.join(', ');

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(m.membershipId ?? '-'),
        TextCellValue(m.name),
        TextCellValue(m.phoneNumber),
        TextCellValue(m.zone ?? '-'),
        TextCellValue(m.designation ?? '-'),
        TextCellValue(allDes.isNotEmpty ? allDes : '-'),
        TextCellValue(m.institution ?? '-'),
        TextCellValue(m.status.toUpperCase()),
        TextCellValue(m.dateOfBirth ?? '-'),
        TextCellValue(m.dateOfJoin ?? '-'),
        TextCellValue(m.dateOfRetirement ?? '-'),
        TextCellValue(m.stateCommitteeRole ?? '-'),
        TextCellValue(m.executiveCommitteeRole ?? '-'),
        TextCellValue(m.zonalCommitteeRole ?? '-'),
        TextCellValue(regDate),
        TextCellValue(m.reviewedByName ?? '-'),
        TextCellValue(m.reviewedAt ?? '-'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final fileName =
        customFileName ??
        'KGRA_${sheetTitle.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    return await downloadFile(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
  }

  // ==========================================
  // 2. Export Committee Members
  // ==========================================

  static Future<String?> exportCommitteeMembers({
    required List<UserModel> members,
    required String
    committeeType, // 'State Committee', 'Executive Committee', 'Zonal Committee'
    String? zone,
    String? customFileName,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final cleanSheetTitle = committeeType.replaceAll(' Members', '');
    excel.rename(defaultSheet, cleanSheetTitle);
    final sheet = excel[cleanSheetTitle];

    final isState = committeeType.toLowerCase().contains('state');
    final isExecutive = committeeType.toLowerCase().contains('executive');

    List<String> headers;
    List<double> widths;

    if (isState) {
      headers = [
        'Sl No',
        'State Committee Role',
        'Full Name',
        'Membership ID',
        'Phone Number',
        'Zone',
        'Official Designation',
        'Institution / Workplace',
        'Date of Joining',
        'Date of Retirement',
      ];
      widths = [8.0, 24.0, 24.0, 18.0, 16.0, 18.0, 22.0, 28.0, 14.0, 14.0];
    } else if (isExecutive) {
      headers = [
        'Sl No',
        'Executive Committee Role',
        'Full Name',
        'Membership ID',
        'Phone Number',
        'Zone',
        'Official Designation',
        'Institution / Workplace',
        'Date of Joining',
        'Date of Retirement',
      ];
      widths = [8.0, 26.0, 24.0, 18.0, 16.0, 18.0, 22.0, 28.0, 14.0, 14.0];
    } else {
      // Zonal Committee
      headers = [
        'Sl No',
        'Zone',
        'Zonal Committee Role',
        'Full Name',
        'Membership ID',
        'Phone Number',
        'Official Designation',
        'Institution / Workplace',
        'Date of Joining',
        'Date of Retirement',
      ];
      widths = [8.0, 18.0, 24.0, 24.0, 18.0, 16.0, 22.0, 28.0, 14.0, 14.0];
    }

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _applyHeaderStyle(sheet, headers.length);

    for (int i = 0; i < widths.length && i < headers.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

    // Sort according to committee hierarchy
    List<UserModel> sorted;
    if (isState) {
      sorted = CommitteeHelper.sortMembers(members, true);
    } else if (isExecutive) {
      sorted = CommitteeHelper.sortMembers(members, false);
    } else {
      sorted = CommitteeHelper.sortZonalMembers(members);
    }

    for (int i = 0; i < sorted.length; i++) {
      final m = sorted[i];
      if (isState) {
        final role = m.stateCommitteeRole?.isNotEmpty == true
            ? m.stateCommitteeRole!
            : CommitteeHelper.getDisplayDesignation(m, true);
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(role),
          TextCellValue(m.name),
          TextCellValue(m.membershipId ?? '-'),
          TextCellValue(m.phoneNumber),
          TextCellValue(m.zone ?? '-'),
          TextCellValue(m.designation ?? '-'),
          TextCellValue(m.institution ?? '-'),
          TextCellValue(m.dateOfJoin ?? '-'),
          TextCellValue(m.dateOfRetirement ?? '-'),
        ]);
      } else if (isExecutive) {
        final role = m.executiveCommitteeRole?.isNotEmpty == true
            ? m.executiveCommitteeRole!
            : CommitteeHelper.getDisplayDesignation(m, false);
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(role),
          TextCellValue(m.name),
          TextCellValue(m.membershipId ?? '-'),
          TextCellValue(m.phoneNumber),
          TextCellValue(m.zone ?? '-'),
          TextCellValue(m.designation ?? '-'),
          TextCellValue(m.institution ?? '-'),
          TextCellValue(m.dateOfJoin ?? '-'),
          TextCellValue(m.dateOfRetirement ?? '-'),
        ]);
      } else {
        // Zonal
        final role = m.zonalCommitteeRole?.isNotEmpty == true
            ? m.zonalCommitteeRole!
            : CommitteeHelper.getDisplayDesignation(m, CommitteeType.zonal);
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(m.zone ?? '-'),
          TextCellValue(role),
          TextCellValue(m.name),
          TextCellValue(m.membershipId ?? '-'),
          TextCellValue(m.phoneNumber),
          TextCellValue(m.designation ?? '-'),
          TextCellValue(m.institution ?? '-'),
          TextCellValue(m.dateOfJoin ?? '-'),
          TextCellValue(m.dateOfRetirement ?? '-'),
        ]);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final zonePart =
        (zone != null && zone.isNotEmpty && zone.toLowerCase() != 'all')
        ? '_${zone.replaceAll(' ', '_')}'
        : '';
    final fileName =
        customFileName ??
        'KGRA_${cleanSheetTitle.replaceAll(' ', '_')}${zonePart}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    return await downloadFile(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
  }

  // ==========================================
  // 3. Export Payment Details
  // ==========================================

  static Future<String?> exportPayments({
    required List<PaymentTransactionModel> payments,
    String? zone,
    String? statusFilter,
    String? customFileName,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    const sheetTitle = 'Payments';
    excel.rename(defaultSheet, sheetTitle);
    final sheet = excel[sheetTitle];

    final headers = [
      'Sl No',
      'Receipt / Payment ID',
      'Order ID',
      'Member Name',
      'Membership ID',
      'Phone Number',
      'Zone',
      'Designation',
      'Institution',
      'Amount (INR)',
      'Currency',
      'Status',
      'Payment Method',
      'Purpose',
      'Financial Year',
      'Payment Date & Time',
      'Platform',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _applyHeaderStyle(sheet, headers.length);

    final widths = [
      8.0,
      24.0,
      24.0,
      24.0,
      18.0,
      16.0,
      18.0,
      22.0,
      28.0,
      16.0,
      10.0,
      14.0,
      16.0,
      26.0,
      16.0,
      22.0,
      14.0,
    ];
    for (int i = 0; i < widths.length && i < headers.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

    for (int i = 0; i < payments.length; i++) {
      final p = payments[i];
      final paidDateStr = p.paidAt != null
          ? _dateTimeFmt.format(p.paidAt!)
          : '-';

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.receiptNumber ?? p.paymentId),
        TextCellValue(p.orderId),
        TextCellValue(p.userName ?? '-'),
        TextCellValue(p.membershipId ?? '-'),
        TextCellValue(p.userPhone ?? '-'),
        TextCellValue(p.zone ?? '-'),
        TextCellValue(p.designation ?? '-'),
        TextCellValue(p.institution ?? '-'),
        DoubleCellValue(p.amount),
        TextCellValue(p.currency),
        TextCellValue(p.status.toUpperCase()),
        TextCellValue(p.paymentMethod?.toUpperCase() ?? '-'),
        TextCellValue(p.purposeLabel ?? p.purpose),
        TextCellValue(p.financialYear ?? '-'),
        TextCellValue(paidDateStr),
        TextCellValue(p.platform ?? '-'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final fileName =
        customFileName ??
        'KGRA_Payment_Details_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    return await downloadFile(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
  }
}
