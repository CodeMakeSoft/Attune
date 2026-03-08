import 'package:flutter/material.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePermissions {
  final bool canEditPersonal;
  final bool canEditJob;
  final bool canEditLegal;

  const ProfilePermissions({
    this.canEditPersonal = false,
    this.canEditJob = false,
    this.canEditLegal = false,
  });

  bool get canEditAny => canEditPersonal || canEditJob || canEditLegal;
}

class ProfileForm extends StatefulWidget {
  final User? user;
  final ProfilePermissions permissions;
  final Function(User) onSave;
  final bool isLoading;
  final List<String> availableDepartments;
  final List<String> availablePositions;

  const ProfileForm({
    super.key,
    required this.user,
    required this.permissions,
    required this.onSave,
    this.isLoading = false,
    this.availableDepartments = const [],
    this.availablePositions = const [],
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  // Personal Controllers
  late TextEditingController _nameController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  DateTime? _birthday;
  String? _gender;

  // Job Controllers
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  String? _contractType;
  DateTime? _hireDate;
  
  // Selection state for dropdowns
  String? _selectedDepartment;
  String? _selectedPosition;

  // Legal Controllers
  late TextEditingController _rfcController;
  late TextEditingController _curpController;
  late TextEditingController _nssController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = widget.user;
    
    // Personal
    _nameController = TextEditingController(text: user?.name ?? '');
    _emergencyContactNameController = TextEditingController(text: user?.emergencyContact['name'] ?? '');
    _emergencyContactPhoneController = TextEditingController(text: user?.emergencyContact['phone'] ?? '');
    
    _birthday = user?.birthday?.toDate();
    _gender = user?.gender;

    // Job
    _departmentController = TextEditingController(text: user?.department ?? '');
    _positionController = TextEditingController(text: user?.position ?? '');
    
    // Initialize Dropdown values
    if (widget.availableDepartments.contains(user?.department)) {
      _selectedDepartment = user?.department;
    }
    if (widget.availablePositions.contains(user?.position)) {
      _selectedPosition = user?.position;
    }

    _contractType = user?.contractType;
    _hireDate = user?.hireDate?.toDate();

    // Legal
    _rfcController = TextEditingController(text: user?.rfc ?? '');
    _curpController = TextEditingController(text: user?.curp ?? '');
    _nssController = TextEditingController(text: user?.nss ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _rfcController.dispose();
    _curpController.dispose();
    _nssController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
       // Logic to prioritize dropdown value/controller
       final dept = widget.availableDepartments.isNotEmpty ? _selectedDepartment : _departmentController.text;
       final pos = widget.availablePositions.isNotEmpty ? _selectedPosition : _positionController.text;
       
       final fullUpdatedUser = User(
        uid: widget.user!.uid,
        email: widget.user!.email,
        companies: widget.user!.companies,
        companyIds: widget.user!.companyIds,
        ownedCompanies: widget.user!.ownedCompanies,
        currentCompanyId: widget.user!.currentCompanyId,
        status: widget.user!.status,
        createdAt: widget.user!.createdAt,
        name: _nameController.text,
        photoUrl: widget.user!.photoUrl,
        birthday: _birthday != null ? Timestamp.fromDate(_birthday!) : null,
        gender: _gender,
        emergencyContact: {
          'name': _emergencyContactNameController.text,
          'phone': _emergencyContactPhoneController.text,
        },
        department: dept ?? '',
        position: pos ?? '',
        contractType: _contractType,
        hireDate: _hireDate != null ? Timestamp.fromDate(_hireDate!) : null,
        rfc: _rfcController.text,
        curp: _curpController.text,
        nss: _nssController.text,
       );

      widget.onSave(fullUpdatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text("No user data"));
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPersonalSection(),
          const SizedBox(height: 24),
          _buildJobSection(),
          const SizedBox(height: 24),
          _buildLegalSection(),
          
          if (widget.permissions.canEditAny) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: widget.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Guardar Cambios"),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    final enabled = widget.permissions.canEditPersonal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Información Personal", FontAwesomeIcons.user),
        
        _buildTextField(
          label: "Nombre Completo",
          controller: _nameController,
          enabled: enabled,
          icon: FontAwesomeIcons.signature,
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        _buildDatePicker(
          label: "F. Nacimiento",
          selectedDate: _birthday,
          enabled: enabled,
          onChanged: (d) => setState(() => _birthday = d),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: "Género",
          value: _gender,
          items: ['Masculino', 'Femenino', 'Otro'],
          enabled: enabled,
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 16),
        Text("Contacto de Emergencia", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildTextField(
          label: "Nombre Contacto",
          controller: _emergencyContactNameController,
          enabled: enabled,
          icon: FontAwesomeIcons.userPlus,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: "Teléfono",
          controller: _emergencyContactPhoneController,
          enabled: enabled,
          icon: FontAwesomeIcons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // UPDATE _buildJobSection
  Widget _buildJobSection() {
    final enabled = widget.permissions.canEditJob;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Información Laboral", FontAwesomeIcons.briefcase),
        
        if (widget.availableDepartments.isNotEmpty)
          _buildDropdown(
            label: "Departamento", 
            value: _selectedDepartment, 
            items: widget.availableDepartments, 
            enabled: enabled, 
            onChanged: (v) => setState(() => _selectedDepartment = v),
          )
        else
          _buildTextField(
            label: "Departamento",
            controller: _departmentController,
            enabled: enabled,
            icon: FontAwesomeIcons.building,
          ),
          
        const SizedBox(height: 16),
        
        if (widget.availablePositions.isNotEmpty)
          _buildDropdown(
            label: "Puesto", 
            value: _selectedPosition, 
            items: widget.availablePositions, 
            enabled: enabled, 
            onChanged: (v) => setState(() => _selectedPosition = v),
          )
        else
          _buildTextField(
            label: "Puesto",
            controller: _positionController,
            enabled: enabled,
            icon: FontAwesomeIcons.idBadge,
          ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: "Tipo Contrato",
                value: _contractType,
                items: ['Planta', 'Temporal', 'Prácticas'],
                enabled: enabled,
                onChanged: (v) => setState(() => _contractType = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(
                label: "F. Contratación",
                selectedDate: _hireDate,
                enabled: enabled,
                onChanged: (d) => setState(() => _hireDate = d),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    final enabled = widget.permissions.canEditLegal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Información Legal", FontAwesomeIcons.fileContract),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "RFC",
                controller: _rfcController,
                enabled: enabled,
                icon: FontAwesomeIcons.passport,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "CURP",
                controller: _curpController,
                enabled: enabled,
                icon: FontAwesomeIcons.fingerprint,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: "NSS",
                controller: _nssController,
                enabled: enabled,
                icon: FontAwesomeIcons.notesMedical,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required bool enabled,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(FontAwesomeIcons.calendar, size: 18),
        ),
        child: Text(
          selectedDate != null
              ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
              : '',
          style: TextStyle(
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      onChanged: enabled ? onChanged : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(FontAwesomeIcons.list, size: 18),
      ),
    );
  }
}
