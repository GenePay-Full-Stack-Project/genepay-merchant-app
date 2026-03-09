import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/merchant_api_service.dart';
import '../../models/merchant_response.dart';
import '../../models/update_merchant_request.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _navy = Color(0xFF1E1E8B);
  static const Color _accent = Color(0xFFFF5722);

  final MerchantApiService _merchantApiService = MerchantApiService();

  MerchantResponse? _merchant;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _isEditMode = false;

  TextEditingController? _businessNameController;
  TextEditingController? _ownerNameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _addressController;
  TextEditingController? _businessTypeController;
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _merchantApiService.initialize();

      // Get merchant ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        throw Exception('Merchant ID not found. Please log in again.');
      }

      // Fetch merchant details
      final response = await _merchantApiService.getMerchant(merchantId);

      if (response.success && response.data != null) {
        setState(() {
          _merchant = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception(response.message ?? 'Failed to load merchant data');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: _accent),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: TextStyle(
                  fontSize: 18,
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMerchantData,
                style: ElevatedButton.styleFrom(backgroundColor: _navy),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_merchant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'No merchant data available',
            style: TextStyle(color: _navy),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E8B)),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _isEditMode ? 'Edit Profile' : 'Profile',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // To balance the row visually
              ],
            ),
            const SizedBox(height: 18),

            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _navy, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _avatarImage != null
                        ? Image.file(
                            _avatarImage!,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 64,
                            color: Color(0xFF6B7280),
                          ),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: GestureDetector(
                    onTap: () async {
                      // open option to pick image or capture photo
                      await _showImageSourceActionSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // white panel with fields
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListView(
                  children: [
                    // show either read-only fields or editable fields depending on _isEditMode
                    if (!_isEditMode) ...[
                      _buildInfoField(
                        'Business Name',
                        _merchant!.businessName,
                        Icons.edit,
                        () {
                          setState(() => _enterEditMode());
                        },
                      ),
                      _buildInfoField(
                        'Owner Name',
                        _merchant!.ownerName ?? 'Not set',
                        null,
                        null,
                      ),
                      _buildInfoField('Email', _merchant!.email, null, null),
                      _buildInfoField(
                        'Phone Number',
                        _merchant!.phoneNumber ?? 'Not set',
                        null,
                        null,
                      ),
                      _buildInfoField(
                        'Business Address',
                        _merchant!.businessAddress ?? 'Not set',
                        null,
                        null,
                      ),
                      _buildInfoField(
                        'Business Type',
                        _merchant!.businessType ?? 'Not set',
                        null,
                        null,
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildEditableField(
                        'Business Name',
                        _businessNameController!,
                      ),
                      _buildEditableField('Owner Name', _ownerNameController!),
                      _buildEditableField('Email', _emailController!),
                      _buildEditableField('Phone Number', _phoneController!),
                      _buildEditableField(
                        'Business Address',
                        _addressController!,
                      ),
                      _buildEditableField(
                        'Business Type',
                        _businessTypeController!,
                      ),
                      const SizedBox(height: 18),
                      if (_isSaving)
                        Center(child: CircularProgressIndicator(color: _navy))
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveEdit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _cancelEdit()),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _navy.withOpacity(0.12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _avatarImage = File(picked.path);
          // enter edit mode when user changes avatar
          if (!_isEditMode) _enterEditMode();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _enterEditMode() {
    // create controllers with current values
    _businessNameController = TextEditingController(
      text: _merchant!.businessName,
    );
    _ownerNameController = TextEditingController(
      text: _merchant!.ownerName ?? '',
    );
    _emailController = TextEditingController(text: _merchant!.email);
    _phoneController = TextEditingController(
      text: _merchant!.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: _merchant!.businessAddress ?? '',
    );
    _businessTypeController = TextEditingController(
      text: _merchant!.businessType ?? '',
    );
    _isEditMode = true;
  }

  Future<void> _saveEdit() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        throw Exception('Merchant ID not found');
      }

      // Create update request with only changed fields
      final request = UpdateMerchantRequest(
        businessName: _businessNameController?.text.trim().isEmpty == true
            ? null
            : _businessNameController?.text.trim(),
        ownerName: _ownerNameController?.text.trim().isEmpty == true
            ? null
            : _ownerNameController?.text.trim(),
        email: _emailController?.text.trim().isEmpty == true
            ? null
            : _emailController?.text.trim(),
        phoneNumber: _phoneController?.text.trim().isEmpty == true
            ? null
            : _phoneController?.text.trim(),
        businessAddress: _addressController?.text.trim().isEmpty == true
            ? null
            : _addressController?.text.trim(),
        businessType: _businessTypeController?.text.trim().isEmpty == true
            ? null
            : _businessTypeController?.text.trim(),
      );

      // Call update API
      final response = await _merchantApiService.updateMerchant(
        merchantId,
        request,
      );

      if (response.success && response.data != null) {
        setState(() {
          _merchant = response.data;
          _disposeControllers();
          _isEditMode = false;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.message ?? 'Failed to update profile');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    _disposeControllers();
    _isEditMode = false;
  }

  void _disposeControllers() {
    _businessNameController?.dispose();
    _ownerNameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _addressController?.dispose();
    _businessTypeController?.dispose();
    _businessNameController = null;
    _ownerNameController = null;
    _emailController = null;
    _phoneController = null;
    _addressController = null;
    _businessTypeController = null;
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _merchantApiService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _navy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _navy.withOpacity(0.14)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _navy, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    IconData? icon,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 2, 32, 111),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 15, 15, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (icon != null)
                  GestureDetector(
                    onTap: onTap,
                    child: Icon(icon, color: const Color(0xFFFF4C3A), size: 20),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
