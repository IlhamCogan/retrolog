import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Import SharedPreferences
import '../../models/motor_model.dart';
import '../../database/db_helper.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<MotorModel> _motorList = [];
  bool _isLoading = true;
  int? _selectedMotorId; // 👈 Variable untuk menyimpan ID motor aktif

  @override
  void initState() {
    super.initState();
    _loadSelectedMotor();
    _refreshMotors();
  }

  // 👈 1. Fungsi membaca motor aktif yang tersimpan
  void _loadSelectedMotor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMotorId = prefs.getInt('selected_motor_id');
    });
  }

  // 👈 2. Fungsi memilih motor aktif & menyimpan ke SharedPreferences
  void _selectMotor(MotorModel motor) async {
    if (motor.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_motor_id', motor.id!);
    await prefs.setString('selected_motor_name', motor.nickname);
    
    setState(() {
      _selectedMotorId = motor.id;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${motor.nickname} dipilih sebagai motor utama! 🏍️️'),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Mengambil daftar motor dari Database SQLite
  void _refreshMotors() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getMotors();
    setState(() {
      _motorList = data;
      _isLoading = false;
      // Jika belum ada motor terpilih, pilih motor pertama secara otomatis
      if (_selectedMotorId == null && _motorList.isNotEmpty && _motorList.first.id != null) {
        _selectMotor(_motorList.first);
      }
    });
  }

  // Modal Tambah Motor Baru ke SQLite
  void _showAddMotorDialog() {
    final nicknameController = TextEditingController();
    final nameController = TextEditingController();
    final yearController = TextEditingController();
    final plateController = TextEditingController();
    final engineController = TextEditingController();
    String selectedStatus = 'Sedang Direstorasi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        const Text('Tambah Motor Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Panggilan Motor',
                        hintText: 'Contoh: Legasi, Srikandi, Si Pitung',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama / Tipe Resmi',
                        hintText: 'Contoh: Honda Astrea Legenda 2',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.two_wheeler),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tahun',
                              hintText: '2002',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: engineController,
                            decoration: const InputDecoration(
                              labelText: 'Kapasitas Mesin',
                              hintText: '100 cc',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: plateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Polisi (Plat)',
                        hintText: 'H 1234 XX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Restorasi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sedang Direstorasi', child: Text('🟢 Sedang Direstorasi')),
                        DropdownMenuItem(value: 'Bisa Dikendarai', child: Text('🟡 Bisa Dikendarai / Daily')),
                        DropdownMenuItem(value: 'Contest Ready', child: Text('🔵 Selesai / Contest Ready')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
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
                      label: const Text('SIMPAN KE GARASI', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          await _dbHelper.insertMotor(MotorModel(
                            nickname: nicknameController.text.isEmpty ? nameController.text : nicknameController.text,
                            name: nameController.text,
                            year: yearController.text.isEmpty ? '-' : yearController.text,
                            plate: plateController.text.isEmpty ? '-' : plateController.text.toUpperCase(),
                            engine: engineController.text.isEmpty ? '100 cc' : engineController.text,
                            status: selectedStatus,
                            progress: '10%',
                          ));

                          _refreshMotors();
                          if (mounted) Navigator.pop(context);
                        }
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

  // Hapus Motor dari SQLite
  void _deleteMotor(int id) async {
    await _dbHelper.deleteMotor(id);
    if (_selectedMotorId == id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_motor_id');
      await prefs.remove('selected_motor_name');
      _selectedMotorId = null;
    }
    _refreshMotors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('KOLEKSI', '${_motorList.length} Motor', Icons.two_wheeler),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatColumn('RESTORASI', '${_motorList.where((m) => m.status == 'Sedang Direstorasi').length} Unit', Icons.build_outlined),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatColumn('SIAP ROAD', '${_motorList.where((m) => m.status != 'Sedang Direstorasi').length} Unit', Icons.verified_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DAFTAR KENDARAAN (TAP UNTUK PILIH UNTUK BERANDA)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                if (_motorList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Belum ada motor di garasi', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ..._motorList.map((item) {
                    bool isSelected = item.id == _selectedMotorId; // 👈 Cek apakah motor ini yang dipilih

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        // 👈 Memberi border emas jika motor sedang dipilih
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFD97706) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _selectMotor(item), // 👈 Tap kartu untuk memilih motor aktif
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.two_wheeler, size: 50, color: Color(0xFFD97706)),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.nickname,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  // 👈 Badge "AKTIF" di pojok kiri atas jika terpilih
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD97706),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.check_circle, size: 12, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'AKTIF DI BERANDA',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      if (item.id != null)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => _deleteMotor(item.id!),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildBadge(Icons.calendar_today, item.year),
                                      const SizedBox(width: 8),
                                      _buildBadge(Icons.badge, item.plate),
                                      const SizedBox(width: 8),
                                      _buildBadge(Icons.speed, item.engine),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Motor'),
        onPressed: _showAddMotorDialog,
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD97706), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}