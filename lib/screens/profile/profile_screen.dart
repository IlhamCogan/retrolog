import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State Data Pengguna (Default Value)
  String _userName = 'Ilham Ramadhan';
  String _userEmail = 'ilham@email.com';
  String _userPhone = '081234567890';
  
  // State Gambar Profil
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // State Preferensi Notifikasi
  bool _notifService = true;
  bool _notifLog = true;
  bool _notifPromo = false;

  // Data State Service Reminders (Default Value)
  List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Ganti Oli Mesin (SAE 20W-50)',
      'dueDate': '10 Oktober 2026',
      'isDone': false,
    },
    {
      'title': 'Setel Celah Busi & Karburator',
      'dueDate': '25 Oktober 2026',
      'isDone': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData(); // 👈 Muat data permanen saat layar dibuka
  }

  // ==========================================
  // LOGIKA PEMUATAN & PENYIMPANAN DATA PERMANEN
  // ==========================================

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? _userName;
      _userEmail = prefs.getString('user_email') ?? _userEmail;
      _userPhone = prefs.getString('user_phone') ?? _userPhone;

      // Load Gambar
      String? imagePath = prefs.getString('user_image_path');
      if (imagePath != null && imagePath.isNotEmpty) {
        _imageFile = XFile(imagePath);
      }

      // Load Notifikasi
      _notifService = prefs.getBool('notif_service') ?? _notifService;
      _notifLog = prefs.getBool('notif_log') ?? _notifLog;
      _notifPromo = prefs.getBool('notif_promo') ?? _notifPromo;

      // Load Reminders (JSON)
      String? remindersJson = prefs.getString('user_reminders');
      if (remindersJson != null && remindersJson.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(remindersJson);
        _reminders = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_email', _userEmail);
    await prefs.setString('user_phone', _userPhone);
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_image_path', path);
  }

  Future<void> _saveNotifPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_service', _notifService);
    await prefs.setBool('notif_log', _notifLog);
    await prefs.setBool('notif_promo', _notifPromo);
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_reminders);
    await prefs.setString('user_reminders', jsonString);
  }

  // ==========================================
  // DIALOG & INTERAKSI USER
  // ==========================================

  // 1. DIALOG EDIT FOTO PROFIL
  void _showEditPhotoDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ubah Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFFD97706)),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() => _imageFile = photo);
                    await _saveImagePath(photo.path); // 👈 Simpan path foto
                    _showToast('Foto berhasil diperbarui dari Kamera!');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0F172A)),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _imageFile = image);
                    await _saveImagePath(image.path); // 👈 Simpan path foto
                    _showToast('Foto berhasil diperbarui dari Galeri!');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. MODAL PENGATURAN PROFIL
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final phoneController = TextEditingController(text: _userPhone);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pengaturan Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  setState(() {
                    _userName = nameController.text;
                    _userEmail = emailController.text;
                    _userPhone = phoneController.text;
                  });
                  await _saveUserData(); // 👈 Simpan data profil ke SharedPreferences
                  if (mounted) Navigator.pop(context);
                  _showToast('Profil berhasil diperbarui!');
                },
                child: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. MODAL KEAMANAN AKUN
  void _showSecurityDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Keamanan Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Saat Ini', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (oldPassController.text.isNotEmpty && newPassController.text.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_password', newPassController.text); // 👈 Simpan password lokal
                    if (mounted) Navigator.pop(context);
                    _showToast('Password berhasil diperbarui!');
                  }
                },
                child: const Text('PERBARUI PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. MODAL PREFERENSI NOTIFIKASI
  void _showNotificationSettingsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preferensi Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Pengingat Servis Berkala'),
                    subtitle: const Text('Notifikasi jadwal ganti oli & perawatan'),
                    activeColor: const Color(0xFFD97706),
                    value: _notifService,
                    onChanged: (val) async {
                      setModalState(() => _notifService = val);
                      setState(() => _notifService = val);
                      await _saveNotifPreferences(); // 👈 Simpan preferensi notif
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Update Log Restorasi'),
                    subtitle: const Text('Pengingat saat mencatat aktivitas restorasi'),
                    activeColor: const Color(0xFFD97706),
                    value: _notifLog,
                    onChanged: (val) async {
                      setModalState(() => _notifLog = val);
                      setState(() => _notifLog = val);
                      await _saveNotifPreferences(); // 👈 Simpan preferensi notif
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Tips & Info Motor Klasik'),
                    subtitle: const Text('Info seputar restorasi dan info bengkel'),
                    activeColor: const Color(0xFFD97706),
                    value: _notifPromo,
                    onChanged: (val) async {
                      setModalState(() => _notifPromo = val);
                      setState(() => _notifPromo = val);
                      await _saveNotifPreferences(); // 👈 Simpan preferensi notif
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // MODAL TAMBAH REMINDER
  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    String selectedSoundType = 'default';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tambah Pengingat Servis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Servis / Perawatan',
                      hintText: 'Contoh: Bersihkan Saringan Oli',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build_circle_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Target Tanggal / Jadwal',
                      hintText: 'Contoh: 15 November 2026',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_note),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: selectedSoundType,
                    decoration: const InputDecoration(
                      labelText: 'Nada Dering Notifikasi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.music_note_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text('🔔 Suara Bawaan Sistem HP')),
                      DropdownMenuItem(value: 'custom', child: Text('🏍️ Suara Engine Custom Retro')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSoundType = val);
                    },
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notification_add_outlined),
                    label: const Text('SIMPAN PENGINGAT'),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        final String titleText = titleController.text;
                        final String dateText = dateController.text.isEmpty ? 'Mendatang' : dateController.text;

                        setState(() {
                          _reminders.add({
                            'title': titleText,
                            'dueDate': dateText,
                            'isDone': false,
                          });
                        });

                        await _saveReminders(); // 👈 Simpan daftar pengingat baru ke SharedPreferences

                        // BUNYIKAN NOTIFIKASI
                        if (selectedSoundType == 'custom') {
                          await NotificationService().showCustomSoundNotification(
                            title: 'Pengingat Servis Terpasang! 🏍️',
                            body: '$titleText dijadwalkan pada $dateText',
                          );
                        } else {
                          await NotificationService().showDefaultSoundNotification(
                            title: 'Pengingat Servis Terpasang! 🔔',
                            body: '$titleText dijadwalkan pada $dateText',
                          );
                        }

                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // DIALOG LOGOUT
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KONFIRMASI LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah kamu yakin ingin keluar dari akun RETROLOG?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. HEADER PROFIL
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showEditPhotoDialog,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF0F172A),
                          backgroundImage: _imageFile != null
                              ? (kIsWeb
                                  ? NetworkImage(_imageFile!.path)
                                  : FileImage(File(_imageFile!.path)) as ImageProvider)
                              : null,
                          child: _imageFile == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. PENGINGAT SERVIS SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PENGINGAT SERVIS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              IconButton(
                icon: const Icon(Icons.add_alert_outlined, color: Color(0xFFD97706), size: 20),
                onPressed: _showAddReminderDialog,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._reminders.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                dense: true,
                value: item['isDone'],
                activeColor: const Color(0xFFD97706),
                title: Text(
                  item['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: item['isDone'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('Jadwal: ${item['dueDate']}'),
                onChanged: (bool? val) async {
                  setState(() {
                    _reminders[idx]['isDone'] = val ?? false;
                  });
                  await _saveReminders(); // 👈 Simpan perubahan centang checklist
                },
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text('PENGATURAN AKUN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),

          // 3. MENU PENGATURAN INTERAKTIF
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined, color: Color(0xFF0F172A)),
                  title: const Text('Pengaturan Profil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showEditProfileDialog,
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Color(0xFF0F172A)),
                  title: const Text('Keamanan Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showSecurityDialog,
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.notifications_none_outlined, color: Color(0xFF0F172A)),
                  title: const Text('Preferensi Notifikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showNotificationSettingsDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. TOMBOL LOGOUT
          Card(
            color: Colors.red.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Keluar Akun',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}