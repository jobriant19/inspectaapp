import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPickerBottomSheet extends StatefulWidget {
  final String lang;
  const UserPickerBottomSheet({super.key, required this.lang});

  @override
  State<UserPickerBottomSheet> createState() => _UserPickerBottomSheetState();
}

class _UserPickerBottomSheetState extends State<UserPickerBottomSheet> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await Supabase.instance.client
        .from('User')
        .select('id_user, nama, gambar_user');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.lang == 'ID' ? 'Sebut Pengguna' : 'Mention User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: widget.lang == 'ID' ? 'Cari pengguna...' : 'Search user...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(widget.lang == 'ID' ? 'Tidak ada pengguna' : 'No users found'));
                }
                
                final filteredUsers = snapshot.data!
                    .where((user) => (user['nama'] as String? ?? '').toLowerCase().contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final avatarUrl = user['gambar_user'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Text((user['nama'] as String? ?? ' ' )[0]) : null,
                      ),
                      title: Text(user['nama'] ?? 'No Name'),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}