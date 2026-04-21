import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    this.initialPhone = '',
    this.initialInstitutionType = 'university',
    this.initialInstitutionName = '',
    this.initialDepartment = '',
    this.initialDateOfBirth = '',
    this.initialAddress = '',
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialInstitutionType;
  final String initialInstitutionName;
  final String initialDepartment;
  final String initialDateOfBirth;
  final String initialAddress;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _institutionName;
  late final TextEditingController _department;
  late final TextEditingController _dateOfBirth;
  late final TextEditingController _address;
  late String _institutionType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _email = TextEditingController(text: widget.initialEmail);
    _phone = TextEditingController(text: widget.initialPhone);
    _institutionType = widget.initialInstitutionType == 'school' ? 'school' : 'university';
    _institutionName = TextEditingController(text: widget.initialInstitutionName);
    _department = TextEditingController(text: widget.initialDepartment);
    _dateOfBirth = TextEditingController(text: widget.initialDateOfBirth);
    _address = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _institutionName.dispose();
    _department.dispose();
    _dateOfBirth.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    await auth.updateProfile(
      fullName: _name.text,
      phone: _phone.text,
      institutionType: _institutionType,
      institutionName: _institutionName.text,
      department: _institutionType == 'university' ? _department.text : null,
      dateOfBirth: _dateOfBirth.text,
      address: _address.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError!)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.pageHPadFor(context);
    final topPad = AppLayout.pageTopPadFor(context);
    final bottomPad = AppLayout.pageBottomPadFor(context);
    final maxWidth = AppLayout.contentMaxWidthFor(context);
    final isWide = AppLayout.formFactorFor(context) != AppFormFactor.mobile;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(child: _field('Name', _name)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Phone number',
                        _phone,
                        keyboard: TextInputType.phone,
                      ),
                    ),
                  ],
                )
              else ...[
                _field('Name', _name),
                _field('Phone number', _phone, keyboard: TextInputType.phone),
              ],
              Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _institutionType,
              decoration: InputDecoration(
                labelText: 'Institution type',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'university', child: Text('University')),
                DropdownMenuItem(value: 'school', child: Text('School')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _institutionType = value);
              },
            ),
              ),
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _institutionType == 'school'
                            ? 'School name'
                            : 'University name',
                        _institutionName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _institutionType == 'university'
                          ? _field('Department (optional)', _department)
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              else ...[
                _field(
                  _institutionType == 'school'
                      ? 'School name'
                      : 'University name',
                  _institutionName,
                ),
                if (_institutionType == 'university')
                  _field('Department (optional)', _department),
              ],
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Date of birth',
                        _dateOfBirth,
                        hint: 'YYYY-MM-DD',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Email', _email, readOnly: true)),
                  ],
                )
              else ...[
                _field('Date of birth', _dateOfBirth, hint: 'YYYY-MM-DD'),
                _field('Email', _email, readOnly: true),
              ],
              _field('Address', _address, maxLines: 3),
              const SizedBox(height: 8),
              Text(
            'Email is managed by your account. Contact support to change it.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
              ),
              const SizedBox(height: 20),
              SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextField(
            controller: c,
            readOnly: readOnly,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
