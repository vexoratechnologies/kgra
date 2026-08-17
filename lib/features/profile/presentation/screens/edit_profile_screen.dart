import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_snack_bar.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// EditProfileScreen allows user to edit their profile details & profile picture.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  late TextEditingController _institutionController;
  late TextEditingController _membershipIdController;
  late TextEditingController _dobController;
  late TextEditingController _dojController;
  late TextEditingController _retirementController;

  String? _selectedZone;
  String? _selectedDesignation;
  String? _newPhotoBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    
    String rawPhone = user?.phoneNumber ?? '';
    if (rawPhone.startsWith('+91')) {
      rawPhone = rawPhone.substring(3);
    } else if (rawPhone.startsWith('91') && rawPhone.length > 10) {
      rawPhone = rawPhone.substring(2);
    }
    _phoneController = TextEditingController(text: rawPhone);

    _designationController = TextEditingController(text: user?.designation ?? '');
    _institutionController = TextEditingController(text: user?.institution ?? '');
    _membershipIdController = TextEditingController(text: user?.membershipId ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    _dojController = TextEditingController(text: user?.dateOfJoin ?? '');
    _retirementController = TextEditingController(text: user?.dateOfRetirement ?? '');
    _selectedZone = user?.zone;
    _selectedDesignation = user?.designation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchZones();
      context.read<AdminProvider>().fetchDesignations();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _institutionController.dispose();
    _membershipIdController.dispose();
    _dobController.dispose();
    _dojController.dispose();
    _retirementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newPhotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    phone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = phone.isNotEmpty ? '+91$phone' : '';
    
    final designation = _designationController.text.trim();
    final institution = _institutionController.text.trim();
    final membershipId = _membershipIdController.text.trim();
    final zone = _selectedZone;
    final dob = _dobController.text.trim();
    final doj = _dojController.text.trim();
    final retirementDate = _retirementController.text.trim();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateUserProfile(
      name: name,
      phoneNumber: fullPhone,
      designation: designation,
      institution: institution,
      photoBase64: _newPhotoBase64,
      zone: zone,
      dateOfBirth: dob,
      dateOfJoin: doj,
      membershipId: membershipId,
      dateOfRetirement: retirementDate,
    );

    if (success && mounted) {
      AppSnackBar.showSuccess(context, 'Profile updated successfully');
      context.pop();
    } else if (mounted) {
      AppSnackBar.showError(
        context,
        authProvider.error ?? 'Failed to update profile details',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CompactAppBar(
        title: 'Edit Profile',
        subtitle: 'Update personal details',
        rightIcon: Icons.person_outline,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Picker Container Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Builder(
                          builder: (context) {
                            ImageProvider? imageProvider;
                            if (_newPhotoBase64 != null) {
                              imageProvider = MemoryImage(base64Decode(_newPhotoBase64!));
                            } else if (user?.profileImageId != null && user!.profileImageId!.startsWith('http')) {
                              imageProvider = NetworkImage(user.profileImageId!);
                            } else if (authProvider.currentUserPhotoBase64 != null &&
                                authProvider.currentUserPhotoBase64!.isNotEmpty) {
                              try {
                                imageProvider = MemoryImage(base64Decode(authProvider.currentUserPhotoBase64!));
                              } catch (_) {}
                            }

                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E293B),
                                border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: imageProvider != null
                                    ? Image(image: imageProvider, fit: BoxFit.cover)
                                    : Center(
                                        child: Text(
                                          user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            elevation: 3,
                            shape: const CircleBorder(),
                            color: const Color(0xFF991B1B),
                            child: InkWell(
                              onTap: _pickImage,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Tap camera icon to update profile picture',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Edit Form Fields Container Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        hintText: 'Enter full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Mobile Number
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: AppRadius.borderLg,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Row(
                              children: [
                                const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '+91',
                                  style: AppTextStyle.bodyMd(color: AppColors.onSurface).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                hintText: '10 digit mobile number',
                                fillColor: Colors.transparent,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Mobile number is required';
                                }
                                if (value.trim().length != 10) {
                                  return 'Enter valid 10-digit number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Designation
                    const Text(
                      'Designation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<AdminProvider>(
                      builder: (context, adminProv, child) {
                        final list = adminProv.designations;
                        String? selectedVal = _selectedDesignation;
                        if (selectedVal != null && !list.contains(selectedVal)) {
                          selectedVal = null;
                        }
                        if (list.isNotEmpty) {
                          return DropdownButtonFormField<String>(
                            value: selectedVal,
                            hint: const Text('Select Designation'),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: list.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDesignation = val;
                                if (val != null) {
                                  _designationController.text = val;
                                }
                              });
                            },
                          );
                        }
                        return TextFormField(
                          controller: _designationController,
                          decoration: const InputDecoration(
                            hintText: 'Enter Designation',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Institution
                    const Text(
                      'Institution',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _institutionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Institution/Hospital',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Zone Dropdown
                    const Text(
                      'Zone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<AdminProvider>(
                      builder: (context, adminProv, child) {
                        final zones = adminProv.zones;
                        return DropdownButtonFormField<String>(
                          value: _selectedZone,
                          hint: const Text('Select Zone'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: zones.map((z) => DropdownMenuItem(
                            value: z,
                            child: Text(z),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedZone = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Membership ID
                    const Text(
                      'Member ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _membershipIdController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Auto-assigned by System (e.g. KGRATVM/01)',
                        helperText: 'Membership ID is assigned automatically',
                        prefixIcon: Icon(Icons.card_membership_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date of Birth
                    const Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Select Date of Birth',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date of Join
                    const Text(
                      'Date of Join',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dojController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Select Date of Join',
                        prefixIcon: Icon(Icons.event_outlined),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _dojController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date of Retirement
                    const Text(
                      'Date of Retirement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _retirementController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Select Date of Retirement',
                        prefixIcon: Icon(Icons.work_off_outlined),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _retirementController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF991B1B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: authProvider.isLoading ? null : _handleSave,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Delete Profile Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _showDeleteProfileDialog(context),
                  child: const Text(
                    'Delete Profile',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        title: const Text(
          'Delete Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
        ),
        content: const Text(
          'Are you sure you want to delete your profile? This will log you out of your account.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Delete Profile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
