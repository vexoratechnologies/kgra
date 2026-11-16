import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/committee_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/admin_provider.dart';

/// EditMemberDialog provides an interface for administrators on web and mobile
/// to edit all profile details, membership details, status, and committee roles of a member.
class EditMemberDialog extends StatefulWidget {
  final UserModel user;

  const EditMemberDialog({
    super.key,
    required this.user,
  });

  /// Opens the dialog and returns true if the member was updated.
  static Future<bool?> show(BuildContext context, UserModel user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditMemberDialog(user: user),
    );
  }

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _membershipIdController;
  late TextEditingController _institutionController;
  late TextEditingController _customDesignationController;
  late TextEditingController _dobController;
  late TextEditingController _dojController;
  late TextEditingController _retirementController;

  String? _selectedZone;
  String? _selectedDesignation;
  bool _isCustomDesignation = false;
  late String _selectedStatus;

  String? _stateCommitteeRole;
  String? _executiveCommitteeRole;
  String? _zonalCommitteeRole;

  String? _newPhotoBase64;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _nameController = TextEditingController(text: user.name);

    String rawPhone = user.phoneNumber;
    if (rawPhone.startsWith('+91')) {
      rawPhone = rawPhone.substring(3);
    } else if (rawPhone.startsWith('91') && rawPhone.length > 10) {
      rawPhone = rawPhone.substring(2);
    }
    _phoneController = TextEditingController(text: rawPhone);

    _membershipIdController =
        TextEditingController(text: user.membershipId ?? '');
    _institutionController =
        TextEditingController(text: user.institution ?? '');

    String normalizeDate(String? d) {
      if (d == null || d.trim().isEmpty) return '';
      final trimmed = d.trim();
      try {
        if (trimmed.contains('-') && trimmed.split('-')[0].length == 4) {
          final dt = DateFormat('yyyy-MM-dd').parse(trimmed);
          return DateFormat('dd-MM-yyyy').format(dt);
        }
      } catch (_) {}
      return trimmed;
    }

    _dobController =
        TextEditingController(text: normalizeDate(user.dateOfBirth));
    _dojController =
        TextEditingController(text: normalizeDate(user.dateOfJoin));
    _retirementController =
        TextEditingController(text: normalizeDate(user.dateOfRetirement));

    _selectedZone = user.zone;
    _selectedStatus = user.status;

    _stateCommitteeRole = user.stateCommitteeRole;
    _executiveCommitteeRole = user.executiveCommitteeRole;
    _zonalCommitteeRole = user.zonalCommitteeRole;

    _selectedDesignation = user.designation;
    _customDesignationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.zones.isEmpty) {
        adminProvider.fetchZones();
      }
      if (adminProvider.designations.isEmpty) {
        adminProvider.fetchDesignations();
      }
      if (user.profileImageId != null &&
          user.profileImageId!.isNotEmpty &&
          !user.profileImageId!.startsWith('http') &&
          !adminProvider.userImages.containsKey(user.uid)) {
        adminProvider.fetchUserImage(user.profileImageId!, user.uid);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _membershipIdController.dispose();
    _institutionController.dispose();
    _customDesignationController.dispose();
    _dobController.dispose();
    _dojController.dispose();
    _retirementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newPhotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final adminProvider = context.read<AdminProvider>();
      final user = widget.user;

      final name = _nameController.text.trim();
      String phone =
          _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      final fullPhone = phone.startsWith('91') && phone.length > 10
          ? '+$phone'
          : (phone.isNotEmpty ? '+91$phone' : user.phoneNumber);

      final membershipId = _membershipIdController.text.trim();
      final institution = _institutionController.text.trim();
      final dob = _dobController.text.trim();
      final doj = _dojController.text.trim();
      final retirement = _retirementController.text.trim();

      String? designation;
      if (_isCustomDesignation) {
        designation = _customDesignationController.text.trim();
      } else {
        designation = _selectedDesignation?.trim();
      }

      String? profileImageId = user.profileImageId;
      if (_newPhotoBase64 != null && _newPhotoBase64!.isNotEmpty) {
        try {
          final storageService = GetIt.instance<StorageService>();
          final bytes = base64Decode(_newPhotoBase64!);
          final downloadUrl = await storageService.uploadImage(
            folderName: 'profile_images',
            docId: user.uid,
            fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            fileBytes: bytes,
          );
          if (downloadUrl.isNotEmpty) {
            profileImageId = downloadUrl;
          } else {
            profileImageId = 'img_${user.uid}';
            await adminProvider.saveUserImage(
              profileImageId,
              _newPhotoBase64!,
              user.uid,
            );
          }
        } catch (_) {
          profileImageId = 'img_${user.uid}';
          await adminProvider.saveUserImage(
            profileImageId,
            _newPhotoBase64!,
            user.uid,
          );
        }
      }

      final isApproved = _selectedStatus == 'approved';

      final hasStateRole = _stateCommitteeRole != null &&
          _stateCommitteeRole!.trim().isNotEmpty &&
          _stateCommitteeRole != 'None';
      final hasExecRole = _executiveCommitteeRole != null &&
          _executiveCommitteeRole!.trim().isNotEmpty &&
          _executiveCommitteeRole != 'None';
      final hasZonalRole = _zonalCommitteeRole != null &&
          _zonalCommitteeRole!.trim().isNotEmpty &&
          _zonalCommitteeRole != 'None';

      final updatedUser = user.copyWith(
        name: name,
        phoneNumber: fullPhone,
        membershipId: membershipId.isNotEmpty ? membershipId : null,
        zone: _selectedZone != null && _selectedZone!.isNotEmpty
            ? _selectedZone
            : null,
        designation: designation != null && designation.isNotEmpty
            ? designation
            : null,
        designations: designation != null && designation.isNotEmpty
            ? [designation]
            : null,
        institution: institution.isNotEmpty ? institution : null,
        dateOfBirth: dob.isNotEmpty ? dob : null,
        dateOfJoin: doj.isNotEmpty ? doj : null,
        dateOfRetirement: retirement.isNotEmpty ? retirement : null,
        profileImageId: profileImageId,
        status: _selectedStatus,
        isApproved: isApproved,
        stateCommitteeRole: hasStateRole ? _stateCommitteeRole : null,
        clearStateCommitteeRole: !hasStateRole,
        executiveCommitteeRole: hasExecRole ? _executiveCommitteeRole : null,
        clearExecutiveCommitteeRole: !hasExecRole,
        zonalCommitteeRole: hasZonalRole ? _zonalCommitteeRole : null,
        clearZonalCommitteeRole: !hasZonalRole,
      );

      final success = await adminProvider.updateUser(updatedUser);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = adminProvider.error ?? 'Failed to update member';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error saving member details: $e';
        });
      }
    }
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'DD-MM-YYYY',
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () => setState(() => controller.clear()),
              )
            : null,
        border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onTap: () async {
        DateTime init = initialDate ?? DateTime.now();
        if (controller.text.trim().isNotEmpty) {
          try {
            init = DateFormat('dd-MM-yyyy').parse(controller.text.trim());
          } catch (_) {
            try {
              init = DateFormat('yyyy-MM-dd').parse(controller.text.trim());
            } catch (_) {}
          }
        }
        final fDate = firstDate ?? DateTime(1920);
        final lDate = lastDate ?? DateTime(2100);
        if (init.isBefore(fDate)) init = fDate;
        if (init.isAfter(lDate)) init = lDate;

        final picked = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: fDate,
          lastDate: lDate,
        );
        if (picked != null) {
          setState(() {
            controller.text = DateFormat('dd-MM-yyyy').format(picked);
          });
        }
      },
    );
  }

  Widget _buildPhotoSection(AdminProvider adminProvider) {
    final user = widget.user;
    final imgBase64 = _newPhotoBase64 ?? adminProvider.userImages[user.uid];
    final hasNetworkImage = user.profileImageId != null &&
        user.profileImageId!.startsWith('http') &&
        _newPhotoBase64 == null;

    ImageProvider? imageProvider;
    if (_newPhotoBase64 != null) {
      imageProvider = MemoryImage(base64Decode(_newPhotoBase64!));
    } else if (hasNetworkImage) {
      imageProvider = NetworkImage(user.profileImageId!);
    } else if (imgBase64 != null) {
      imageProvider = MemoryImage(base64Decode(imgBase64));
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor:
                    AppColors.brandPrimary.withValues(alpha: 0.1),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppColors.brandPrimary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickImage,
                    child: const Padding(
                      padding: EdgeInsets.all(7.0),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined, size: 15),
            label: Text(
              _newPhotoBase64 != null ? 'Change Photo' : 'Upload New Photo',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brandPrimary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandSecondary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isWide,
    required Widget first,
    required Widget second,
    Widget? third,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 16),
          Expanded(child: second),
          if (third != null) ...[
            const SizedBox(width: 16),
            Expanded(child: third),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          first,
          const SizedBox(height: 12),
          second,
          if (third != null) ...[
            const SizedBox(height: 12),
            third,
          ],
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    // Prepare cleaned zones list
    final zones = adminProvider.zones
        .where((z) {
          final clean = z.trim().toLowerCase();
          return clean.isNotEmpty &&
              !clean.contains('exec') &&
              !clean.contains('state') &&
              clean != 'all';
        })
        .toSet()
        .toList();

    if (_selectedZone != null &&
        _selectedZone!.isNotEmpty &&
        !zones.contains(_selectedZone)) {
      zones.insert(0, _selectedZone!);
    }

    // Prepare designations list
    final designations = List<String>.from(adminProvider.designations);
    if (_selectedDesignation != null &&
        _selectedDesignation!.isNotEmpty &&
        !designations.contains(_selectedDesignation)) {
      designations.insert(0, _selectedDesignation!);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: ClipRRect(
          borderRadius: AppRadius.borderLg,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Member Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                  Text(
                    'UID: ${widget.user.uid}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 550;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Photo Section
                        _buildPhotoSection(adminProvider),
                        const SizedBox(height: AppSpacing.sm),

                        // Section 1: Personal Info
                        _buildSectionHeader(
                          'Personal Information',
                          Icons.person_outline,
                        ),

                        _buildResponsiveRow(
                          isWide: isWide,
                          first: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          second: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              prefixText: '+91 ',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final digits = v.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10) {
                                return 'Enter valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section 2: Association & Work
                        _buildSectionHeader(
                          'Membership & Employment',
                          Icons.badge_outlined,
                        ),

                        _buildResponsiveRow(
                          isWide: isWide,
                          first: TextFormField(
                            controller: _membershipIdController,
                            decoration: InputDecoration(
                              labelText: 'Membership ID',
                              hintText: 'e.g. KGRA/SZ/001',
                              prefixIcon: const Icon(
                                Icons.card_membership_outlined,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          second: DropdownButtonFormField<String>(
                            value: (_selectedZone != null &&
                                    zones.contains(_selectedZone))
                                ? _selectedZone
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Zone',
                              prefixIcon:
                                  const Icon(Icons.map_outlined, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text(
                                  'Unassigned / None',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...zones.map(
                                (z) => DropdownMenuItem(
                                  value: z,
                                  child: Text(z),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedZone =
                                    (val != null && val.isNotEmpty)
                                        ? val
                                        : null;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildResponsiveRow(
                          isWide: isWide,
                          first: DropdownButtonFormField<String>(
                            value: _isCustomDesignation
                                ? '__CUSTOM__'
                                : (_selectedDesignation != null &&
                                        designations
                                            .contains(_selectedDesignation))
                                    ? _selectedDesignation
                                    : null,
                            decoration: InputDecoration(
                              labelText: 'Designation',
                              prefixIcon:
                                  const Icon(Icons.work_outline, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text(
                                  'None',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...designations.map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ),
                              ),
                              const DropdownMenuItem<String>(
                                value: '__CUSTOM__',
                                child: Text(
                                  '+ Custom Designation...',
                                  style: TextStyle(
                                    color: AppColors.brandPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                if (val == '__CUSTOM__') {
                                  _isCustomDesignation = true;
                                } else {
                                  _isCustomDesignation = false;
                                  _selectedDesignation =
                                      (val != null && val.isNotEmpty)
                                          ? val
                                          : null;
                                }
                              });
                            },
                          ),
                          second: TextFormField(
                            controller: _institutionController,
                            decoration: InputDecoration(
                              labelText: 'Institution / Office',
                              prefixIcon: const Icon(
                                Icons.business_outlined,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        if (_isCustomDesignation) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customDesignationController,
                            decoration: InputDecoration(
                              labelText: 'Enter Custom Designation *',
                              prefixIcon:
                                  const Icon(Icons.edit_note, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) {
                              if (_isCustomDesignation &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Custom designation is required';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Section 3: Important Dates
                        _buildSectionHeader(
                          'Important Dates',
                          Icons.event_outlined,
                        ),

                        _buildResponsiveRow(
                          isWide: isWide,
                          first: _buildDateField(
                            context: context,
                            label: 'Date of Birth',
                            controller: _dobController,
                            lastDate: DateTime.now(),
                          ),
                          second: _buildDateField(
                            context: context,
                            label: 'Date of Join',
                            controller: _dojController,
                            lastDate: DateTime.now(),
                          ),
                          third: _buildDateField(
                            context: context,
                            label: 'Retirement Date',
                            controller: _retirementController,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section 4: Membership Status
                        _buildSectionHeader(
                          'Membership Status',
                          Icons.verified_user_outlined,
                        ),

                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Approval Status *',
                            prefixIcon: Icon(
                              _selectedStatus == 'approved'
                                  ? Icons.check_circle_outline
                                  : _selectedStatus == 'pending'
                                      ? Icons.hourglass_empty
                                      : Icons.cancel_outlined,
                              size: 18,
                              color: _selectedStatus == 'approved'
                                  ? Colors.green
                                  : _selectedStatus == 'pending'
                                      ? Colors.orange
                                      : AppColors.error,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderMd,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pending (Under Review)'),
                            ),
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('Approved (Active Member)'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Rejected'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Section 5: Committee Roles
                        _buildSectionHeader(
                          'Committee Roles (Optional)',
                          Icons.groups_outlined,
                        ),

                        _buildResponsiveRow(
                          isWide: isWide,
                          first: DropdownButtonFormField<String>(
                            value: (_stateCommitteeRole != null &&
                                    CommitteeHelper.defaultStateDesignations
                                        .contains(_stateCommitteeRole))
                                ? _stateCommitteeRole
                                : 'None',
                            decoration: InputDecoration(
                              labelText: 'State Committee Role',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'None',
                                child: Text(
                                  'None',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...CommitteeHelper.defaultStateDesignations.map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _stateCommitteeRole = val),
                          ),
                          second: DropdownButtonFormField<String>(
                            value: (_executiveCommitteeRole != null &&
                                    CommitteeHelper
                                        .defaultExecutiveDesignations
                                        .contains(_executiveCommitteeRole))
                                ? _executiveCommitteeRole
                                : 'None',
                            decoration: InputDecoration(
                              labelText: 'Executive Committee Role',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'None',
                                child: Text(
                                  'None',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...CommitteeHelper
                                  .defaultExecutiveDesignations
                                  .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _executiveCommitteeRole = val),
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: (_zonalCommitteeRole != null &&
                                  CommitteeHelper.defaultZonalDesignations
                                      .contains(_zonalCommitteeRole))
                              ? _zonalCommitteeRole
                              : 'None',
                          decoration: InputDecoration(
                            labelText: 'Zonal Committee Role',
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderMd,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'None',
                              child: Text(
                                'None',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...CommitteeHelper.defaultZonalDesignations.map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _zonalCommitteeRole = val),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
