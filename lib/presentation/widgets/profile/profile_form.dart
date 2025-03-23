import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../../core/logger_config.dart';
import '../../../data/models/profile_model.dart';
import '../../../state/app_state.dart';
import '../common/buttons/gradient_button.dart';

/// Widget de formulario para crear o editar un perfil
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _logger = LoggerConfig.logger;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
                FormBuilderValidators.maxLength(50, errorText: 'No debe exceder los 50 caracteres'),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'stepsPerRevolution',
              decoration: const InputDecoration(
                labelText: 'Pasos por revolución',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.rotate_right),
              ),
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
                FormBuilderValidators.integer(errorText: 'Ingrese un número entero'),
                FormBuilderValidators.min(1, errorText: 'El valor debe ser mayor o igual a 1'),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'distancePerRevolution',
              decoration: const InputDecoration(
                labelText: 'Distancia por revolución (mm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
                FormBuilderValidators.numeric(errorText: 'Ingrese un valor numérico válido'),
                FormBuilderValidators.min(0.1, errorText: 'El valor debe ser mayor o igual a 0.1'),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'screwSensitivity',
              decoration: const InputDecoration(
                labelText: 'Sensibilidad de tornillo (mm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
                FormBuilderValidators.numeric(errorText: 'Ingrese un valor numérico válido'),
                FormBuilderValidators.min(0, errorText: 'El valor debe ser mayor o igual a 0'),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'maxDistance',
              decoration: const InputDecoration(
                labelText: 'Distancia máxima (mm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.space_bar),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
                FormBuilderValidators.numeric(errorText: 'Ingrese un valor numérico válido'),
                FormBuilderValidators.min(1, errorText: 'El valor debe ser mayor o igual a 1'),
              ]),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: GradientButton(
        text: 'Crear perfil',
        onPressed: _submitForm,
        icon: Icons.save,
        width: MediaQuery.of(context).size.width * 0.6,
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSubmitting = true);
      
      try {
        final formData = _formKey.currentState!.value;
        _logger.d('Datos del formulario: $formData');
        
        // Convertir los valores de texto a números
        final profile = ProfileModel(
          name: formData['name'].toString(),
          stepsPerRevolution: int.tryParse(formData['stepsPerRevolution'].toString()) ?? 1,
          distancePerRevolution: double.tryParse(formData['distancePerRevolution'].toString()) ?? 0,
          screwSensitivity: double.tryParse(formData['screwSensitivity'].toString()) ?? 0,
          maxDistance: double.tryParse(formData['maxDistance'].toString()) ?? 0,
        );
        
        final appState = Provider.of<AppState>(context, listen: false);
        final success = await appState.saveProfile(profile);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Perfil "${profile.name}" guardado correctamente')),
          );
          
          // Limpiar el formulario
          _formKey.currentState?.reset();
          
          // Navegar a la pantalla de inicio
          _logger.d('Navegando a la pantalla de inicio después de guardar el perfil');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      } catch (e) {
        _logger.e('Error al guardar perfil: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar perfil: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      _logger.w('Formulario inválido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor corrige los errores en el formulario')),
      );
    }
  }
} 