import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EditProfilePage extends StatefulWidget {
  final String username;
  final String bio;

  const EditProfilePage({super.key, required this.username, required this.bio});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    _usernameCtrl.text = widget.username;
    _bioCtrl.text = widget.bio;
  }

  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  // Saving passwords
  Future<void> _saveProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isSaving = true);
    try {
      await supabase
          .from('profiles')
          .update({
            'username': _usernameCtrl.text.trim(),
            'bio': _bioCtrl.text.trim(),
          })
          .eq('id', userId);
      if (!mounted) return;
      Navigator.pop(context); //back to profile
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 6) {
      _showSnack('At least 6 characters', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordCtrl.text),
      );
      _newPasswordCtrl.clear();
      _showSnack('Password changed!');
    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6B4226),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Username',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Tell readers about yourself...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4226),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const Divider(height: 48),
            const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'New password',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B4226),
                  side: const BorderSide(color: Color(0xFF6B4226)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  //build