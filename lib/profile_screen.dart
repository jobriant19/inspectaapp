import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String lang;
  const ProfileScreen({super.key, required this.lang});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedJabatan;
  bool _isLoading = false;

  final Map<String, Map<String, String>> _txt = {
    'EN': {'title': 'Profile', 'name': 'Name', 'phone': 'Phone', 'role': 'Job Title', 'save': 'Save Changes', 'logout': 'Logout', 'success': 'Profile Updated'},
    'ID': {'title': 'Profil', 'name': 'Nama', 'phone': 'Telepon', 'role': 'Jabatan', 'save': 'Simpan Perubahan', 'logout': 'Keluar', 'success': 'Profil Diperbarui'},
    'ZH': {'title': '个人资料', 'name': '姓名', 'phone': '电话', 'role': '职位', 'save': '保存更改', 'logout': '登出', 'success': '个人资料已更新'},
  };

  String getTxt(String key) => _txt[widget.lang]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userAuth = Supabase.instance.client.auth.currentUser;
    if (userAuth == null) return;
    
    final data = await Supabase.instance.client.from('User').select('nama, phone, id_jabatan, Jabatan(nama_jabatan)').eq('id_user', userAuth.id).single();
    setState(() {
      _nameController.text = data['nama'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _selectedJabatan = data['Jabatan'] != null ? data['Jabatan']['nama_jabatan'] : 'Staff';
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      int idJabatan = 4;
      if(_selectedJabatan == 'Eksekutif') idJabatan = 1;
      if(_selectedJabatan == 'Manager') idJabatan = 2;
      if(_selectedJabatan == 'Kasie') idJabatan = 3;

      await Supabase.instance.client.from('User').update({
        'nama': _nameController.text,
        'phone': _phoneController.text,
        'id_jabatan': idJabatan,
      }).eq('id_user', userAuth!.id);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('success')), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getTxt('title')), backgroundColor: const Color(0xFF00C9E4)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: getTxt('name'), border: const OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _phoneController, decoration: InputDecoration(labelText: getTxt('phone'), border: const OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedJabatan,
              decoration: InputDecoration(labelText: getTxt('role'), border: const OutlineInputBorder()),
              items: ['Eksekutif', 'Manager', 'Kasie', 'Staff'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => _selectedJabatan = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9E4)),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading ? const CircularProgressIndicator() : Text(getTxt('save'), style: const TextStyle(color: Colors.white)),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(getTxt('logout'), style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              },
            )
          ],
        ),
      ),
    );
  }
}