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
  late TextEditingController _phoneController;
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
    _phoneController = TextEditingController(text: user?.phone ?? '');
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
    _phoneController.dispose();
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
      FocusScope.of(context).unfocus();
      final dept = widget.availableDepartments.isNotEmpty ? _selectedDepartment : widget.user?.department;
      final pos = widget.availablePositions.isNotEmpty ? _selectedPosition : widget.user?.position;
       
      final fullUpdatedUser = User(
        uid: widget.user!.uid,
        email: widget.user!.email,
        companies: widget.user!.companies,
        companyIds: widget.user!.companyIds,
        ownedCompanies: widget.user!.ownedCompanies,
        currentCompanyId: widget.user!.currentCompanyId,
        status: widget.user!.status,
        createdAt: widget.user!.createdAt,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: widget.user!.photoUrl,
        birthday: _birthday != null ? Timestamp.fromDate(_birthday!) : null,
        gender: _gender,
        emergencyContact: {
          'name': _emergencyContactNameController.text.trim(),
          'phone': _emergencyContactPhoneController.text.trim(),
        },
        department: dept ?? '',
        position: pos ?? '',
        contractType: _contractType,
        hireDate: _hireDate != null ? Timestamp.fromDate(_hireDate!) : null,
        rfc: _rfcController.text.toUpperCase().trim(),
        curp: _curpController.text.toUpperCase().trim(),
        nss: _nssController.text.trim(),
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
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v)) {
              return 'El nombre solo debe contener letras';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: "Teléfono",
          controller: _phoneController,
          enabled: enabled,
          icon: FontAwesomeIcons.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
              return 'El teléfono solo debe contener números';
            }
            return null;
          },
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
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
              return 'El teléfono debe tener 10 dígitos';
            } 
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildJobSection() {
    final enabled = widget.permissions.canEditJob;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Información Laboral", FontAwesomeIcons.briefcase),
        
        if (enabled) ...[
          _buildDropdown(
            label: "Departamento", 
            value: _selectedDepartment, 
            items: widget.availableDepartments, 
            enabled: true, 
            onChanged: (v) => setState(() => _selectedDepartment = v),
            hint: widget.availableDepartments.isEmpty ? "Configurar en Organización" : "Selecciona un departamento",
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: "Puesto", 
            value: _selectedPosition, 
            items: widget.availablePositions, 
            enabled: true, 
            onChanged: (v) => setState(() => _selectedPosition = v),
            hint: widget.availablePositions.isEmpty ? "Configurar en Organización" : "Selecciona un puesto",
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Tipo Contrato",
                  value: _contractType,
                  items: const ['Planta', 'Temporal', 'Prácticas', 'Honorarios'],
                  enabled: true,
                  onChanged: (v) => setState(() => _contractType = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: "F. Contratación",
                  selectedDate: _hireDate,
                  enabled: true,
                  onChanged: (d) => setState(() => _hireDate = d),
                ),
              ),
            ],
          ),
        ] else ...[
          // MODO DE SOLO LECTURA PARA EL PERFIL DEL EMPLEADO
          _buildTextField(
            label: "Departamento",
            controller: TextEditingController(
              text: (widget.user?.department?.isNotEmpty == true) 
                  ? widget.user!.department 
                  : 'No asignado',
            ),
            enabled: false,
            icon: FontAwesomeIcons.building,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Puesto",
            controller: TextEditingController(
              text: (widget.user?.position?.isNotEmpty == true) 
                  ? widget.user!.position 
                  : 'No asignado',
            ),
            enabled: false,
            icon: FontAwesomeIcons.idBadge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: "Tipo Contrato",
                  controller: TextEditingController(text: _contractType ?? 'No asignado'),
                  enabled: false,
                  icon: FontAwesomeIcons.fileSignature,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: "F. Contratación",
                  controller: TextEditingController(
                    text: _hireDate != null 
                        ? "${_hireDate!.day.toString().padLeft(2, '0')}/${_hireDate!.month.toString().padLeft(2, '0')}/${_hireDate!.year}"
                        : 'No asignada'
                  ),
                  enabled: false,
                  icon: FontAwesomeIcons.calendarDay,
                ),
              ),
            ],
          ),
        ],
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
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    if (!RegExp(r'^[A-Z0-9]{12,13}$').hasMatch(v.toUpperCase())) {
                      return 'RFC inválido';
                    }
                  }
                  return null;
                },
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
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    // 4 Letras, 6 Números, 6 Letras, 2 Letras/Números
                    if (!RegExp(r'^[A-Z]{4}[0-9]{6}[A-Z]{6}[A-Z0-9]{2}$').hasMatch(v.toUpperCase())) {
                      return 'CURP inválida';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: "NSS",
                controller: _nssController,
                enabled: enabled,
                icon: FontAwesomeIcons.notesMedical,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    // Exactamente 11 dígitos numéricos
                    if (!RegExp(r'^[0-9]{11}$').hasMatch(v)) {
                      return 'NSS debe tener 11 dígitos';
                    }
                  }
                  return null;
                },
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
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      onChanged: enabled ? onChanged : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(FontAwesomeIcons.list, size: 18),
      ),
    );
  }
}
