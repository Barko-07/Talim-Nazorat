import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;

/// Hisobot jadvalini haqiqiy Excel fayliga (.xlsx) aylantiradi: birinchi
/// qator — qalin sarlavha, ustunlar kengligi matnga mos, raqamlar raqam
/// sifatida (Excel'da qo'shish va saralash ishlaydi).
///
/// Manba — ReportExportService yaratadigan CSV (UTF-8 BOM, vergul, qo'shtirnoq).
Uint8List csvToXlsx(String csv, {required String sheetName}) {
  final rows = parseCsv(csv);
  final book = xl.Excel.createExcel();
  final defaultSheet = book.getDefaultSheet() ?? 'Sheet1';
  final name = _safeSheetName(sheetName);
  book.rename(defaultSheet, name);
  final sheet = book[name];

  final widths = <int, int>{};
  for (var r = 0; r < rows.length; r++) {
    final cells = <xl.CellValue?>[];
    for (var c = 0; c < rows[r].length; c++) {
      final v = rows[r][c].trim();
      widths[c] = (widths[c] ?? 0) < v.length ? v.length : widths[c]!;
      cells.add(r > 0 ? _valueOf(v) : xl.TextCellValue(v));
    }
    sheet.appendRow(cells);
  }

  if (rows.isNotEmpty) {
    final header = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromInt(0xFFE8F0FC),
      verticalAlign: xl.VerticalAlign.Center,
    );
    for (var c = 0; c < rows.first.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = header;
    }
  }
  widths.forEach((c, w) {
    sheet.setColumnWidth(c, (w + 3).clamp(8, 60).toDouble());
  });

  return Uint8List.fromList(book.encode() ?? const <int>[]);
}

xl.CellValue _valueOf(String v) {
  if (RegExp(r'^-?\d{1,12}$').hasMatch(v)) return xl.IntCellValue(int.parse(v));
  if (RegExp(r'^-?\d{1,12}\.\d+$').hasMatch(v)) {
    return xl.DoubleCellValue(double.parse(v));
  }
  return xl.TextCellValue(v);
}

String _safeSheetName(String s) {
  final clean = s.replaceAll(RegExp(r'[\[\]\*\?/\\:]'), ' ').trim();
  return clean.isEmpty ? 'Hisobot' : (clean.length > 31 ? clean.substring(0, 31) : clean);
}

/// Oddiy CSV o'quvchi: vergul bilan ajratilgan, qo'shtirnoq ichida vergul va
/// qator ko'chishi bo'lishi mumkin, "" — bitta qo'shtirnoq.
List<List<String>> parseCsv(String input) {
  var text = input;
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((c) => c.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  row.add(field.toString());
  if (row.any((c) => c.isNotEmpty)) rows.add(row);
  return rows;
}
