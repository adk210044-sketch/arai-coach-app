// reference_table_card.dart — 法令の数値比較表などを表示するカードウィジェット。
// アプリ全体の青系「スタサプ的」デザイントークンに準拠。

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/reference_tables.dart';

class ReferenceTableCard extends StatelessWidget {
  final ReferenceTable table;

  const ReferenceTableCard({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primarySoft, width: 1.4),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('📊', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  table.title,
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          if (table.note != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                table.note!,
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textMute,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Table(
        border: TableBorder.all(
          color: AppColors.border,
          width: 1,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        columnWidths: table.headers.length == 2
            ? const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1)}
            : null,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.primarySoft),
            children: [
              for (final h in table.headers)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          for (int i = 0; i < table.rows.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : AppColors.bgSoft,
              ),
              children: [
                for (final cell in table.rows[i])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Text(
                      cell,
                      style: const TextStyle(
                        fontSize: AppFontSize.md,
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
