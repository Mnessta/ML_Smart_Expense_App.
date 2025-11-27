import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class ExportHelper {
  static Future<File> exportExpensesToJson(List<ExpenseModel> expenses) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/expenses_backup.json');
    final List<Map<String, dynamic>> data = expenses.map((ExpenseModel e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(<String, dynamic>{'expenses': data}));
    return file;
  }

  static Future<File> exportExpensesToCsv(List<ExpenseModel> expenses) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/expenses_export.csv');
    final StringBuffer sb = StringBuffer('id,amount,category,date,note,paymentMethod,isSynced\n');
    for (final ExpenseModel e in expenses) {
      sb.writeln('${e.id},${e.amount},${e.category},${e.date.toIso8601String()},${e.note ?? ''},${e.paymentMethod},${e.isSynced}');
    }
    await file.writeAsString(sb.toString());
    return file;
  }

  static Future<File> exportExpensesToPdf(List<ExpenseModel> expenses) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/expenses_export.pdf');
    
    // Create PDF document
    final pw.Document pdf = pw.Document();
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');
    final DateFormat headerDateFormat = DateFormat('MMMM dd, yyyy');
    
    // Calculate totals
    final double totalExpenses = expenses
        .where((e) => e.type == TransactionType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
    final double totalIncome = expenses
        .where((e) => e.type == TransactionType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    final double balance = totalIncome - totalExpenses;
    
    // Group expenses by date
    final Map<String, List<ExpenseModel>> expensesByDate = {};
    for (final expense in expenses) {
      final String dateKey = dateFormat.format(expense.date);
      expensesByDate.putIfAbsent(dateKey, () => []).add(expense);
    }
    
    // Sort dates in descending order
    final List<String> sortedDates = expensesByDate.keys.toList()
      ..sort((a, b) {
        final DateTime dateA = dateFormat.parse(a);
        final DateTime dateB = dateFormat.parse(b);
        return dateB.compareTo(dateA);
      });
    
    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return <pw.Widget>[
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text(
                    'Expense Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    headerDateFormat.format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text('Total Expenses:'),
                      pw.Text(
                        totalExpenses.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text('Total Income:'),
                      pw.Text(
                        totalIncome.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Balance:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        balance.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: balance >= 0 ? PdfColors.green700 : PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Total Transactions: ${expenses.length}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Transactions by Date
            pw.Text(
              'Transactions',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Build transaction list
            ...sortedDates.map((dateKey) {
              final List<ExpenseModel> dayExpenses = expensesByDate[dateKey]!;
              dayExpenses.sort((a, b) => b.date.compareTo(a.date));
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      dateKey,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  ...dayExpenses.map((expense) {
                    final bool isExpense = expense.type == TransactionType.expense;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        children: <pw.Widget>[
                          pw.Container(
                            width: 4,
                            height: 40,
                            decoration: pw.BoxDecoration(
                              color: isExpense ? PdfColors.red700 : PdfColors.green700,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: <pw.Widget>[
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: <pw.Widget>[
                                    pw.Text(
                                      expense.category,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    pw.Text(
                                      '${isExpense ? '-' : '+'}${expense.amount.toStringAsFixed(2)}',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14,
                                        color: isExpense ? PdfColors.red700 : PdfColors.green700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (expense.note != null && expense.note!.isNotEmpty)
                                  pw.Text(
                                    expense.note!,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                pw.SizedBox(height: 4),
                                pw.Row(
                                  children: <pw.Widget>[
                                    pw.Text(
                                      timeFormat.format(expense.date),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                    pw.SizedBox(width: 10),
                                    pw.Text(
                                      '• ${expense.paymentMethod}',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ];
        },
      ),
    );
    
    // Save PDF to file
    final List<int> pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);
    
    return file;
  }
}































