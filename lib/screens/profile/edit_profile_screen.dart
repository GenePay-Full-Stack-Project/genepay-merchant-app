import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.initialValues});

  final Map<String, String>? initialValues;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  static const Color _navy = Color(0xFF1E1E8B);
  static const Color _accent = Color(0xFFFF5722);

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final vals = widget.initialValues;
    if (vals != null) {
      _nameController.text = vals['name'] ?? '';
      _nicController.text = vals['nic'] ?? '';
      _emailController.text = vals['email'] ?? '';
      _phoneController.text = vals['phone'] ?? '';
    } else {
      // default values
      _nameController.text = 'Melissa Peters';
      _nicController.text = '200162523625';
      _emailController.text = 'melpeters@gmail.com';
      _phoneController.text = '+94 71 435 1387';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              'Edit Profile',
              style: TextStyle(color: _navy, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),

            // avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _navy, width: 6),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: const ClipOval(child: Icon(Icons.person, size: 60, color: Color(0xFF6B7280))),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: ListView(
                  children: [
                    _buildEditField('Name', _nameController),
                    _buildEditField('NIC', _nicController),
                    _buildEditField('Email', _emailController),
                    _buildEditField('Phone Number', _phoneController),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: () {
                        // return updated values back to caller
                        Navigator.pop(context, {
                          'name': _nameController.text,
                          'nic': _nicController.text,
                          'email': _emailController.text,
                          'phone': _phoneController.text,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}
