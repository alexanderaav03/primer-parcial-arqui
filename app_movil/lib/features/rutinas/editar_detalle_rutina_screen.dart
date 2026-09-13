import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../models/ejercicio_detalle.dart';
import 'rutinas_provider.dart';

/// Edita series/repeticiones/peso/descansos/RPE/sesiones de un ejercicio ya
/// agregado a una rutina. El ejercicio en sí (cuál es) no se puede cambiar
/// acá -para eso se elimina el detalle y se agrega uno nuevo-, por eso no
/// hay selector de ejercicio, solo los valores numéricos.
class EditarDetalleRutinaScreen extends ConsumerStatefulWidget {
  final int rutinaId;
  final EjercicioDetalle detalle;

  const EditarDetalleRutinaScreen({super.key, required this.rutinaId, required this.detalle});

  @override
  ConsumerState<EditarDetalleRutinaScreen> createState() => _EditarDetalleRutinaScreenState();
}

class _EditarDetalleRutinaScreenState extends ConsumerState<EditarDetalleRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repeticionesCtrl;
  late final TextEditingController _sesionesPorSemanaCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _descansoSerieCtrl;
  late final TextEditingController _descansoEjercicioCtrl;

  late int _rpe;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final detalle = widget.detalle;
    _seriesCtrl = TextEditingController(text: detalle.series.toString());
    _repeticionesCtrl = TextEditingController(text: detalle.repeticiones.toString());
    _sesionesPorSemanaCtrl = TextEditingController(text: detalle.sesionesPorSemana.toString());
    _pesoCtrl = TextEditingController(text: formatNumeroSinDecimales(detalle.peso.toDouble()));
    _descansoSerieCtrl = TextEditingController(text: detalle.descansoSerie);
    _descansoEjercicioCtrl = TextEditingController(text: detalle.descansoEjercicio);
    _rpe = detalle.rpe;
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repeticionesCtrl.dispose();
    _sesionesPorSemanaCtrl.dispose();
    _pesoCtrl.dispose();
    _descansoSerieCtrl.dispose();
    _descansoEjercicioCtrl.dispose();
    super.dispose();
  }

  String? _validarEntero(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    if (int.tryParse(value.trim()) == null) return 'Debe ser un número';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await editarDetalle(
        ref,
        rutinaId: widget.rutinaId,
        detalleId: widget.detalle.detalleId,
        repeticiones: int.parse(_repeticionesCtrl.text.trim()),
        series: int.parse(_seriesCtrl.text.trim()),
        sesionesPorSemana: int.parse(_sesionesPorSemanaCtrl.text.trim()),
        peso: num.parse(_pesoCtrl.text.trim()),
        descansoSerie: _descansoSerieCtrl.text.trim(),
        descansoEjercicio: _descansoEjercicioCtrl.text.trim(),
        rpe: _rpe,
      );

      ref.invalidate(rutinaDetalleProvider(widget.rutinaId));

      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _error = friendlyMessage(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      Text(widget.detalle.nombre, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seriesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Series'),
                              validator: _validarEntero,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repeticionesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Repeticiones'),
                              validator: _validarEntero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sesionesPorSemanaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sesiones por semana',
                          prefixIcon: Icon(Icons.event_repeat_outlined),
                        ),
                        validator: _validarEntero,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pesoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          prefixIcon: Icon(Icons.fitness_center),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa el peso';
                          if (num.tryParse(value.trim()) == null) return 'Peso inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _descansoSerieCtrl,
                              decoration: const InputDecoration(labelText: 'Descanso serie'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _descansoEjercicioCtrl,
                              decoration: const InputDecoration(labelText: 'Descanso ejercicio'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty) ? 'Requerido' : null,
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
                        onPressed: _loading ? null : _guardar,
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
