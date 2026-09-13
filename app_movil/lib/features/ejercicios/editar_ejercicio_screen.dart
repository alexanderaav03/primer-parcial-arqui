import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_banco.dart';
import 'ejercicio_detalle_provider.dart';
import 'ejercicios_provider.dart';

int? _parseIntOrNull(String texto) => texto.trim().isEmpty ? null : int.tryParse(texto.trim());
num? _parseNumOrNull(String texto) => texto.trim().isEmpty ? null : num.tryParse(texto.trim());

/// PUT /api/ejercicios/{id} es un reemplazo completo, así que este formulario
/// precarga cada campo -incluidos imagen_url/video_url- para no perder esos
/// datos si el instructor solo quería tocar el nombre o los valores sugeridos.
class EditarEjercicioScreen extends ConsumerStatefulWidget {
  final EjercicioBanco ejercicio;

  const EditarEjercicioScreen({super.key, required this.ejercicio});

  @override
  ConsumerState<EditarEjercicioScreen> createState() => _EditarEjercicioScreenState();
}

class _EditarEjercicioScreenState extends ConsumerState<EditarEjercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _imagenUrlCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repeticionesCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _descansoSerieCtrl;
  late final TextEditingController _descansoEjercicioCtrl;

  late int _rpe;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.ejercicio;
    _nombreCtrl = TextEditingController(text: e.nombre);
    _descripcionCtrl = TextEditingController(text: e.descripcion);
    _imagenUrlCtrl = TextEditingController(text: e.imagenUrl ?? '');
    _videoUrlCtrl = TextEditingController(text: e.videoUrl ?? '');
    _seriesCtrl = TextEditingController(text: e.seriesSugeridas?.toString() ?? '');
    _repeticionesCtrl = TextEditingController(text: e.repeticionesSugeridas?.toString() ?? '');
    _pesoCtrl = TextEditingController(text: e.pesoSugerido?.toString() ?? '');
    _descansoSerieCtrl = TextEditingController(text: e.descansoSerieSugerido ?? '');
    _descansoEjercicioCtrl = TextEditingController(text: e.descansoEjercicioSugerido ?? '');
    _rpe = e.rpeSugerido ?? 6;
  }

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
      await editarEjercicio(
        ref,
        ejercicioId: widget.ejercicio.id,
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

      // Refresca el detalle y la lista del banco para que se vean los cambios.
      ref.invalidate(ejercicioDetalleProvider(widget.ejercicio.id));
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
      appBar: AppBar(title: const Text('Editar ejercicio')),
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
                            : const Text('Guardar cambios'),
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
