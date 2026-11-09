import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/log_model.dart';
import '../../database/db_helper.dart';
import 'widgets/total_cost_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<LogModel> _logs = [];
  bool _isLoading = true;
  int _budgetCap = 5000000;
  String _selectedCategoryFilter = 'Semua';
  String _userName = 'Ilham';

  // State Motor Aktif dari Garage
  int? _selectedMotorId;
  String _activeMotorName = 'Motor Klasik (Pilih di Garage)';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initDashboardData();
    _dbHelper.autoDeleteOldLogs(daysOlderThan: 365);
  }

  // Memuat profil, data motor aktif, limit budget spesifik motor, dan logbook-nya
  Future<void> _initDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final int? motorId = prefs.getInt('selected_motor_id');
      final String motorName = prefs.getString('selected_motor_name') ?? 'Motor Klasik (Pilih di Garage)';

      int budget = 5000000;
      List<LogModel> logList = [];

      // Load budget cap & logs khusus motor yang aktif
      if (motorId != null) {
        budget = prefs.getInt('budget_cap_$motorId') ?? 5000000;
        logList = await _dbHelper.getLogsByMotorId(motorId);
      } else {
        budget = prefs.getInt('budget_cap') ?? 5000000;
        logList = await _dbHelper.getLogs();
      }

      if (mounted) {
        setState(() {
          _selectedMotorId = motorId;
          _activeMotorName = motorName;
          _budgetCap = budget;
          _logs = logList; // 👈 PENTING: _logs di-assign di dalam setState agar UI terbarui
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        String fullName = prefs.getString('user_name') ?? prefs.getString('name') ?? 'Ilham Ramadhan';
        _userName = fullName.trim().split(' ').first;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // Menyimpan Limit Budget khusus ID motor yang aktif
  Future<void> _saveBudgetCap(int newCap) async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedMotorId != null) {
      await prefs.setInt('budget_cap_$_selectedMotorId', newCap);
    } else {
      await prefs.setInt('budget_cap', newCap);
    }
    if (mounted) {
      setState(() {
        _budgetCap = newCap;
      });
    }
  }

  int get _totalCost {
    int total = 0;
    for (var item in _logs) {
      total += item.cost;
    }
    return total;
  }

  List<LogModel> get _filteredLogs {
    if (_selectedCategoryFilter == 'Semua') return _logs;
    return _logs.where((log) => log.category == _selectedCategoryFilter).toList();
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // CETAK PDF DINAMIS KHUSUS MOTOR TERPILIH
  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'RETROLOG GARAGE MANAGEMENT',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text('Jurnal Perawatan & Restorasi Kendaraan', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Pemilik: $_userName', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Unit Active: $_activeMotorName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              pw.Text('Rincian Pengerjaan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Kategori', 'Judul Pengerjaan', 'Tanggal', 'Biaya'],
                data: _logs.map((log) => [
                  log.category,
                  log.title,
                  log.date,
                  _formatRupiah(log.cost),
                ]).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL BIAYA RESTORASI:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatRupiah(_totalCost), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Laporan_Restorasi_${_activeMotorName.replaceAll(' ', '_')}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Restorasi_${_activeMotorName.replaceAll(' ', '_')}.pdf',
      );
    }
  }

  void _showEditBudgetDialog() {
    final budgetController = TextEditingController(text: _budgetCap.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atur Limit Budget (${_activeMotorName.split(' ').first})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Batas Maksimal Budget (Rp)',
              hintText: 'Contoh: 10000000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                int? newCap = int.tryParse(budgetController.text);
                if (newCap != null && newCap > 0) {
                  _saveBudgetCap(newCap);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Limit budget restorasi berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showPdfPreviewDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.picture_as_pdf, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Text('Pratinjau Laporan Jurnal (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: const [
                            Text('RETROLOG GARAGE MANAGEMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                            Text('Jurnal Perawatan & Restorasi Kendaraan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            SizedBox(height: 8),
                            Divider(thickness: 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Pemilik: $_userName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text('Unit Active: $_activeMotorName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      const SizedBox(height: 16),
                      const Text('Rincian Pengerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      ..._logs.map((log) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('• ${log.title} (${log.category}) - ${log.date}', style: const TextStyle(fontSize: 11)),
                                ),
                                Text(_formatRupiah(log.cost), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL BIAYA RESTORASI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(_formatRupiah(_totalCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('UNDUH / CETAK LAPORAN PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _generateAndPrintPdf();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddLogDialog() {
    final titleController = TextEditingController();
    final costController = TextEditingController();
    String selectedCategory = 'Mesin';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formattedDateStr = "${selectedDate.day} ${_getNamaBulan(selectedDate.month)} ${selectedDate.year}";

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tambah Log (${_activeMotorName.split(' ').first})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Pengerjaan / Parts',
                        hintText: 'Contoh: Ganti Oli & Busi, Cat Frame',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Restorasi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Mesin', child: Text('⚙️ Mesin & Performa')),
                        DropdownMenuItem(value: 'Bodi', child: Text('🎨 Bodi & Repaint')),
                        DropdownMenuItem(value: 'Kaki-kaki', child: Text('🛞 Kaki-kaki & Ban')),
                        DropdownMenuItem(value: 'Kelistrikan', child: Text('⚡ Kelistrikan & Lampu')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pengerjaan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(formattedDateStr, style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Biaya (Rp)',
                        hintText: 'Contoh: 150000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('SIMPAN CATATAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final String titleText = titleController.text.trim();
                        final String costText = costController.text.trim();

                        if (titleText.isEmpty || costText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Judul dan Biaya tidak boleh kosong!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final int costValue = int.tryParse(costText) ?? 0;

                        // Menyimpan Log baru lengkap dengan motor_id yang sedang aktif
                        await _dbHelper.insertLog(LogModel(
                          title: titleText,
                          category: selectedCategory,
                          date: formattedDateStr,
                          cost: costValue,
                          motorId: _selectedMotorId, // 👈 Terikat dengan motor aktif
                        ));

                        if (mounted) {
                          setState(() {
                            _selectedCategoryFilter = 'Semua';
                          });
                          Navigator.pop(context); // Tutup dialog
                        }

                        // Panggil refresh data beranda
                        await _initDashboardData();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getNamaBulan(int month) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month - 1];
  }

  void _deleteLog(int id) async {
    await _dbHelper.deleteLog(id);
    await _initDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Semua', 'Mesin', 'Bodi', 'Kaki-kaki', 'Kelistrikan'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getGreeting()}, $_userName 👋',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Banner Informasi Motor Terpilih
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD97706).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Motor Aktif: $_activeMotorName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                TotalCostCard(
                  formattedCost: _formatRupiah(_totalCost),
                  totalCost: _totalCost,
                  budgetCap: _budgetCap,
                  totalLogs: _logs.length,
                  onExportPdf: _showPdfPreviewDialog,
                  onEditBudget: _showEditBudgetDialog,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AKTIVITAS & LOGBOOK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextButton.icon(
                      onPressed: _showAddLogDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFFD97706)),
                      label: const Text('Tambah Log', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategoryFilter == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD97706),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() => _selectedCategoryFilter = category);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_filteredLogs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('Belum ada catatan restorasi untuk motor ini', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ..._filteredLogs.map((log) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.build_circle_outlined, color: Color(0xFFD97706)),
                          title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${log.date} • Kategori: ${log.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_formatRupiah(log.cost), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              if (log.id != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () => _deleteLog(log.id!),
                                ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}