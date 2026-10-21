import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/category_provider.dart';

class PieChartView extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalExpense;

  const PieChartView({
    super.key,
    required this.categoryTotals,
    required this.totalExpense,
  });

  @override
  State<PieChartView> createState() => _PieChartViewState();
}

class _PieChartViewState extends State<PieChartView> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    if (widget.totalExpense == 0 || widget.categoryTotals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 54,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Nessuna spesa per questo mese',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Grafico a Torta
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: entries.asMap().entries.map((item) {
                final index = item.key;
                final entry = item.value;
                final isTouched = index == _touchedIndex;
                final fontSize = isTouched ? 15.0 : 12.0;
                final radius = isTouched ? 65.0 : 54.0;
                final catProvider = context.watch<CategoryProvider?>();
                final cat =
                    catProvider?.getCategory(
                      entry.key,
                      TransactionType.expense,
                    ) ??
                    TransactionCategories.getCategory(
                      entry.key,
                      TransactionType.expense,
                    );
                final percentage = (entry.value / widget.totalExpense) * 100;

                return PieChartSectionData(
                  color: cat.color,
                  value: entry.value,
                  title: percentage >= 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.map((entry) {
              final catProvider = context.watch<CategoryProvider?>();
              final cat =
                  catProvider?.getCategory(
                    entry.key,
                    TransactionType.expense,
                  ) ??
                  TransactionCategories.getCategory(
                    entry.key,
                    TransactionType.expense,
                  );
              final percentage = (entry.value / widget.totalExpense) * 100;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${percentage.toStringAsFixed(1)}% - ${currencyFormat.format(entry.value)})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
