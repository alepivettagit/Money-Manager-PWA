import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/pie_chart_view.dart';
import '../widgets/category_breakdown.dart';

enum AnalyticsViewMode { pie, bars, both }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _currentMonth = DateTime.now();
  AnalyticsViewMode _viewMode = AnalyticsViewMode.both;

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final monthFormat = DateFormat('MMMM yyyy', 'it_IT');
    final txProvider = context.watch<TransactionProvider>();

    final monthTxs = txProvider.getTransactionsForMonth(_currentMonth);
    final categoryTotals = txProvider.getExpenseCategoriesForMonth(
      _currentMonth,
    );
    final totalExpense = txProvider.getTotalExpenseForMonth(_currentMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Ripartizione Spese')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selettore Mese
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: _previousMonth,
                    tooltip: 'Mese precedente',
                  ),
                  Text(
                    monthFormat.format(_currentMonth).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: _nextMonth,
                    tooltip: 'Mese successivo',
                  ),
                ],
              ),
            ),

            // Card Totale Speso nel Mese
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totale Spese del Mese',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Suddivise per categoria',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(totalExpense),
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Button: Torta / Barre / Entrambi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SegmentedButton<AnalyticsViewMode>(
                segments: const [
                  ButtonSegment(
                    value: AnalyticsViewMode.pie,
                    icon: Icon(Icons.pie_chart_rounded, size: 18),
                    label: Text('Torta', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: AnalyticsViewMode.bars,
                    icon: Icon(Icons.bar_chart_rounded, size: 18),
                    label: Text('Barre', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: AnalyticsViewMode.both,
                    icon: Icon(Icons.dashboard_rounded, size: 18),
                    label: Text('Entrambi', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _viewMode = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 8),

            // Vista Grafico a Torta
            if (_viewMode == AnalyticsViewMode.pie ||
                _viewMode == AnalyticsViewMode.both)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafico a Torta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PieChartView(
                      categoryTotals: categoryTotals,
                      totalExpense: totalExpense,
                    ),
                  ],
                ),
              ),

            // Vista Barre Progressiva (stile Home)
            if (_viewMode == AnalyticsViewMode.bars ||
                _viewMode == AnalyticsViewMode.both)
              CategoryBreakdown(transactions: monthTxs),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
