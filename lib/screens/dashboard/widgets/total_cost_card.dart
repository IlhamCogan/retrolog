import 'package:flutter/material.dart';

class TotalCostCard extends StatelessWidget {
  final String formattedCost;
  final int totalCost;
  final int budgetCap;
  final int totalLogs;
  final VoidCallback onExportPdf;
  final VoidCallback onEditBudget; // 👈 1. Tambah variabel ini

  const TotalCostCard({
    super.key,
    required this.formattedCost,
    required this.totalCost,
    required this.budgetCap,
    required this.totalLogs,
    required this.onExportPdf,
    required this.onEditBudget, // 👈 2. Tambah di konstruktor
  });

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = (totalCost / budgetCap).clamp(0.0, 1.0);
    Color progressColor = progress > 0.9
        ? Colors.redAccent
        : (progress > 0.75 ? Colors.amber : Colors.greenAccent);

    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 👈 1. Bungkus judul dengan Expanded agar teks bisa fleksibel & tidak mendorong elemen kanan
                const Expanded(
                  child: Text(
                    'TOTAL BIAYA RESTORASI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}% Limit',
                        style: TextStyle(color: progressColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onExportPdf,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('PDF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)), // 👈 Singkat sedikit jadi PDF agar lebih lega
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedCost,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onEditBudget,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Text(
                          'Limit Budget: ${_formatRupiah(budgetCap)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ),
                Text('Total Log: $totalLogs Item', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}