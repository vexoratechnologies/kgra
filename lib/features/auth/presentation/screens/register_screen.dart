import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_snack_bar.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// RegisterScreen allows new members to sign up (Name and Mobile only).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _institutionController = TextEditingController();
  final _dobController = TextEditingController();
  final _dojController = TextEditingController();
  final _membershipIdController = TextEditingController();
  final _retirementController = TextEditingController();
  String? _selectedZone;
  String? _selectedDesignation;
  String? _photoBase64;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchZones();
      context.read<AdminProvider>().fetchDesignations();
    });
    final authProvider = context.read<AuthProvider>();
    if (authProvider.verificationPhone != null && authProvider.verificationPhone!.length >= 10) {
      final rawPhone = authProvider.verificationPhone!;
      final numberOnly = rawPhone.startsWith('+91') ? rawPhone.substring(3) : rawPhone;
      _phoneController.text = numberOnly;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _institutionController.dispose();
    _dobController.dispose();
    _dojController.dispose();
    _membershipIdController.dispose();
    _retirementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  void _clearImage() {
    setState(() {
      _photoBase64 = null;
    });
  }

  Future<void> _handleRegister() async {
    if (_photoBase64 == null || _photoBase64!.isEmpty) {
      AppSnackBar.showError(context, 'Profile picture is mandatory. Please select a profile photo.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(2);
    }
    phone = phone.replaceAll(RegExp(r'\D'), '');
    final designation = _designationController.text.trim();
    final institution = _institutionController.text.trim();
    final zone = _selectedZone;
    final dob = _dobController.text.trim();
    final doj = _dojController.text.trim();
    final membershipId = _membershipIdController.text.trim();
    final retirementDate = _retirementController.text.trim();
    final fullPhone = '+91$phone';

    final authProvider = context.read<AuthProvider>();
    authProvider.clearStates();
    
    // Check if the user is already registered
    final exists = await authProvider.checkUserExists(fullPhone);
    if (authProvider.error != null && mounted) {
      AppSnackBar.showError(context, authProvider.error!);
      return;
    }
    
    if (exists && mounted) {
      AppSnackBar.showError(context, 'This mobile number is already registered. Please log in instead.');
      context.go(AppRoutes.login);
      return;
    }

    // Trigger OTP sending and save registration name temporarily
    final success = await authProvider.sendOtp(
      fullPhone,
      tempName: name,
      tempDesignation: designation,
      tempInstitution: institution,
      tempPhotoBase64: _photoBase64,
      tempZone: zone,
      tempDateOfBirth: dob,
      tempDateOfJoin: doj,
      tempMembershipId: membershipId,
      tempDateOfRetirement: retirementDate,
    );

    if (success && mounted) {
      // Send them to verify OTP. Once verified, account will be created
      context.go(AppRoutes.otp);
    } else if (mounted) {
      AppSnackBar.showError(context, authProvider.error ?? 'Failed to send verification code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.brandBackground,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=1000'
            ),
            opacity: 0.03,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(
                        color: AppColors.brandSecondary.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandSecondary.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registration Form',
                          style: AppTextStyle.titleLg(color: AppColors.brandPrimary).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Fill details to submit request to admin',
                          style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),

                        // Photo Picker Widget (Mandatory)
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.08),
                                backgroundImage: _photoBase64 != null
                                    ? MemoryImage(base64Decode(_photoBase64!))
                                    : null,
                                child: _photoBase64 == null
                                    ? const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 40,
                                        color: AppColors.brandPrimary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Material(
                                  elevation: 2,
                                  shape: const CircleBorder(),
                                  color: AppColors.brandPrimary,
                                  child: InkWell(
                                    onTap: _photoBase64 == null ? _pickImage : _clearImage,
                                    customBorder: const CircleBorder(),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        _photoBase64 == null ? Icons.add : Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Profile Photo ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '*',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' (Mandatory)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Full Name Label & Input
                        Text(
                          'Full Name',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Enter valid name (min 3 characters)';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),

                        // Designation Label & Input
                        Text(
                          'Designation',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Consumer<AdminProvider>(
                          builder: (context, adminProv, child) {
                            final designationsList = adminProv.designations;
                            String? currentVal = _selectedDesignation;
                            if (currentVal != null && !designationsList.contains(currentVal)) {
                              currentVal = null;
                            }
                            return DropdownButtonFormField<String>(
                              value: currentVal,
                              hint: const Text('Select your designation'),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: designationsList.map((d) => DropdownMenuItem(
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
                              validator: (value) => value == null ? 'Designation is required' : null,
                            );
                          },
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),

                        // Zone Dropdown Selection
                        Text(
                          'Zone',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Consumer<AdminProvider>(
                          builder: (context, adminProv, child) {
                            final zonesList = adminProv.zones;
                            return DropdownButtonFormField<String>(
                              value: _selectedZone,
                              hint: const Text('Select your zone'),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                              items: zonesList.map((z) => DropdownMenuItem(
                                value: z,
                                child: Text(z),
                              )).toList(),
                              onChanged: (val) async {
                                setState(() {
                                  _selectedZone = val;
                                });
                                if (val != null && val.isNotEmpty) {
                                  final nextId = await context.read<AuthProvider>().peekNextMembershipId(val);
                                  if (mounted) {
                                    _membershipIdController.text = nextId;
                                  }
                                }
                              },
                              validator: (value) => value == null ? 'Zone is required' : null,
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Date of Birth DatePicker
                        Text(
                          'Date of Birth',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Date of Birth is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Date of Join DatePicker
                        Text(
                          'Date of Join',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Date of Join is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Membership ID Text Field
                        Text(
                          'Membership ID',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _membershipIdController,
                          readOnly: true,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: 'Auto-generated (e.g. KGRATVM/01)',
                            helperText: 'Auto-assigned sequentially based on selected zone',
                            prefixIcon: Icon(Icons.card_membership_outlined),
                          ),
                          validator: (value) {
                            if ((value == null || value.trim().isEmpty) && _selectedZone == null) {
                              return 'Please select a Zone to assign Membership ID';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Date of Retirement DatePicker
                        Text(
                          'Date of Retirement',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Date of Retirement is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        
                        // Mobile Number Label & Custom Input
                        Text(
                          'Mobile Number',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
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
                                    hintText: '10 digit number',
                                    fillColor: Colors.transparent,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Phone number required';
                                    }
                                    if (value.trim().length != 10 || 
                                        !RegExp(r'^\d+$').hasMatch(value.trim())) {
                                      return 'Enter valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Register / Request Code Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleRegister,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify & Register'),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Back to Sign In option
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                              ),
                              GestureDetector(
                                onTap: () {
                                  authProvider.clearStates();
                                  context.go(AppRoutes.login);
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
