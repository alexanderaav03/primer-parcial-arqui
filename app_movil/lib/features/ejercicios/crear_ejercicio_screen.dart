import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'ejercicios_provider.dart';

int? _parseIntOrNull(String texto) => texto.trim().isEmpty ? null : int.tryParse(texto.trim());
num? _parseNumOrNull(String texto) => texto.trim().isEmpty ? null : num.tryParse(texto.trim());

/// POST /api/ejercicios (solo instructor). Mismo formulario que
/// EditarEjercicioScreen -nombre, descripción, imagen/video, valores
/// sugeridos-, pero arrancando vacío en vez de precargado.
class CrearEjercicioScreen extends ConsumerStatefulWidget {
  const CrearEjercicioScreen({super.key});

  @override
  ConsumerState<CrearEjercicioScreen> createState() => _CrearEjercicioScreenState();
}

class _CrearEjercicioScreenState extends ConsumerState<CrearEjercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _imagenUrlCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _repeticionesCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _descansoSerieCtrl = TextEditingController();
  final _descansoEjercicioCtrl = TextEditingController();

  int _rpe = 6;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _imagenUrlCtrl.dispose();
    _videoUrlCtrl.dispose();
    _seriesCtrl.dispose();
    _repeticionesCtrl.dispose();
    _pesoCtrl.dispose();
    _descansoSerieCtrl.dispose();
    _descansoEjercicioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await crearEjercicio(
        ref,
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        imagenUrl: _imagenUrlCtrl.text.trim().isEmpty ? null : _imagenUrlCtrl.text.trim(),
        videoUrl: _videoUrlCtrl.text.trim().isEmpty ? null : _videoUrlCtrl.text.trim(),
        seriesSugeridas: _parseIntOrNull(_seriesCtrl.text),
        repeticionesSugeridas: _parseIntOrNull(_repeticionesCtrl.text),
        pesoSugerido: _parseNumOrNull(_pesoCtrl.text),
        descansoSerieSugerido: _descansoSerieCtrl.text.trim().isEmpty ? null : _descansoSerieCtrl.text.trim(),
        descansoEjercicioSugerido:
            _descansoEjercicioCtrl.text.trim().isEmpty ? null : _descansoEjercicioCtrl.text.trim(),
        rpeSugerido: _rpe,
      );

      // Refresca la lista de EjerciciosScreen para que el nuevo ejercicio
      // aparezca sin salir y volver a entrar.
      ref.invalidate(ejerciciosBancoProvider);

      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _error = friendlyMessage(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validarNumero(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    return num.tryParse(value.trim()) == null ? 'Debe ser un número' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ejercicio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Datos del ejercicio', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.fitness_center_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Ingresa la descripción' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imagenUrlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL de imagen (opcional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _videoUrlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL de video (opcional)',
                          prefixIcon: Icon(Icons.play_circle_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Valores sugeridos (opcionales)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seriesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Series'),
                              validator: _validarNumero,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repeticionesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Repeticiones'),
                              validator: _validarNumero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pesoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        validator: _validarNumero,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _descansoSerieCtrl,
                              decoration: const InputDecoration(labelText: 'Descanso serie'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _descansoEjercicioCtrl,
                              decoration: const InputDecoration(labelText: 'Descanso ejercicio'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('RPE: $_rpe', style: Theme.of(context).textTheme.bodyMedium),
                      Slider(
                        value: _rpe.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_rpe',
                        onChanged: (value) => setState(() => _rpe = value.round()),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Crear ejercicio'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
