import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../ejercicios/ejercicios_provider.dart';
import '../models/ejercicio_banco.dart';
import 'rutinas_provider.dart';

/// Representa, solo para esta pantalla, un ejercicio ya agregado a la
/// rutina en la sesión actual -no viene de ningún endpoint, se arma con
/// los mismos datos que se acaban de enviar en el POST-.
class _DetalleAgregadoUI {
  final int ejercicioId;
  final String nombreEjercicio;
  final int series;
  final int repeticiones;

  const _DetalleAgregadoUI({
    required this.ejercicioId,
    required this.nombreEjercicio,
    required this.series,
    required this.repeticiones,
  });
}

class AgregarEjercicioRutinaScreen extends ConsumerStatefulWidget {
  final int rutinaId;
  final int clienteId;

  const AgregarEjercicioRutinaScreen({
    super.key,
    required this.rutinaId,
    required this.clienteId,
  });

  @override
  ConsumerState<AgregarEjercicioRutinaScreen> createState() =>
      _AgregarEjercicioRutinaScreenState();
}

class _AgregarEjercicioRutinaScreenState
    extends ConsumerState<AgregarEjercicioRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seriesCtrl = TextEditingController();
  final _repeticionesCtrl = TextEditingController();
  final _sesionesPorSemanaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _descansoSerieCtrl = TextEditingController();
  final _descansoEjercicioCtrl = TextEditingController();

  EjercicioBanco? _ejercicioSeleccionado;
  int _rpe = 6;
  bool _loading = false;
  String? _error;
  final List<_DetalleAgregadoUI> _agregados = [];

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

  /// Precarga el formulario con los valores sugeridos del banco (si el
  /// ejercicio los tiene); si no, deja los campos en blanco. El instructor
  /// puede editar cualquiera de los dos casos antes de enviar.
  void _onEjercicioSeleccionado(EjercicioBanco? ejercicio) {
    setState(() {
      _ejercicioSeleccionado = ejercicio;
      _seriesCtrl.text = ejercicio?.seriesSugeridas?.toString() ?? '';
      _repeticionesCtrl.text =
          ejercicio?.repeticionesSugeridas?.toString() ?? '';
      _sesionesPorSemanaCtrl.clear();
      _pesoCtrl.text = ejercicio?.pesoSugerido?.toString() ?? '';
      _descansoSerieCtrl.text = ejercicio?.descansoSerieSugerido ?? '';
      _descansoEjercicioCtrl.text = ejercicio?.descansoEjercicioSugerido ?? '';
      _rpe = ejercicio?.rpeSugerido ?? 6;
      _error = null;
    });
  }

  Future<void> _agregar() async {
    final ejercicio = _ejercicioSeleccionado;
    if (ejercicio == null) {
      setState(() => _error = 'Selecciona un ejercicio');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final series = int.parse(_seriesCtrl.text.trim());
    final repeticiones = int.parse(_repeticionesCtrl.text.trim());
    final sesionesPorSemana = int.parse(_sesionesPorSemanaCtrl.text.trim());

    try {
      await agregarDetalle(
        ref,
        rutinaId: widget.rutinaId,
        ejercicioId: ejercicio.id,
        repeticiones: repeticiones,
        series: series,
        sesionesPorSemana: sesionesPorSemana,
        peso: num.parse(_pesoCtrl.text.trim()),
        descansoSerie: _descansoSerieCtrl.text.trim(),
        descansoEjercicio: _descansoEjercicioCtrl.text.trim(),
        rpe: _rpe,
      );

      setState(() {
        _agregados.add(
          _DetalleAgregadoUI(
            ejercicioId: ejercicio.id,
            nombreEjercicio: ejercicio.nombre,
            series: series,
            repeticiones: repeticiones,
          ),
        );
        _ejercicioSeleccionado = null;
        _seriesCtrl.clear();
        _repeticionesCtrl.clear();
        _sesionesPorSemanaCtrl.clear();
        _pesoCtrl.clear();
        _descansoSerieCtrl.clear();
        _descansoEjercicioCtrl.clear();
        _rpe = 6;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ejercicio.nombre} agregado a la rutina')),
        );
      }
    } on DioException catch (e) {
      setState(() => _error = friendlyMessage(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _terminar() {
    // La lista de RutinasScreen se refresca sola al volver.
    ref.invalidate(rutinasProvider(widget.clienteId));
    Navigator.of(context).pop();
  }

  String? _validarEntero(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    if (int.tryParse(value.trim()) == null) return 'Debe ser un número';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ejerciciosAsync = ref.watch(ejerciciosBancoProvider);
    final detalleAsync = ref.watch(rutinaDetalleProvider(widget.rutinaId));

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar ejercicios')),
      body: ejerciciosAsync.when(
        loading: () =>
            const LoadingView(message: 'Cargando banco de ejercicios...'),
        error: (error, _) => AsyncErrorView(
          message: friendlyMessage(error),
          onRetry: () => ref.invalidate(ejerciciosBancoProvider),
        ),
        data: (ejercicios) {
          if (ejercicios.isEmpty) {
            return const EmptyView(
              message: 'Todavía no tienes ejercicios en tu banco para asignar.',
              icon: Icons.fitness_center_outlined,
            );
          }

          // Ejercicios que ya están en esta rutina (cargados del backend o
          // agregados recién en esta misma sesión) no se pueden volver a
          // elegir - evita duplicados sin depender solo del backend.
          final idsExistentes =
              detalleAsync.whenOrNull(
                data: (d) => d.ejercicios.map((e) => e.ejercicioId).toSet(),
              ) ??
              <int>{};
          final idsExcluidos = {
            ...idsExistentes,
            for (final a in _agregados) a.ejercicioId,
          };
          final disponibles = ejercicios
              .where((e) => !idsExcluidos.contains(e.id))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (disponibles.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Todos los ejercicios de tu banco ya están en esta rutina.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Agregar ejercicio',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<EjercicioBanco>(
                            value: _ejercicioSeleccionado,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Ejercicio',
                              prefixIcon: Icon(Icons.fitness_center_outlined),
                            ),
                            items: [
                              for (final ejercicio in disponibles)
                                DropdownMenuItem(
                                  value: ejercicio,
                                  child: Text(
                                    ejercicio.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _onEjercicioSeleccionado,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _seriesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Series',
                                  ),
                                  validator: _validarEntero,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _repeticionesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Repeticiones',
                                  ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              prefixIcon: Icon(Icons.fitness_center),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el peso';
                              }
                              if (num.tryParse(value.trim()) == null) {
                                return 'Peso inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _descansoSerieCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Descanso serie',
                                  ),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _descansoEjercicioCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Descanso ejercicio',
                                  ),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'RPE: $_rpe',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _rpe.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_rpe',
                            onChanged: (value) =>
                                setState(() => _rpe = value.round()),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loading ? null : _agregar,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Agregar ejercicio a la rutina'),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (_agregados.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Ejercicios agregados (${_agregados.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final item in _agregados) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(item.nombreEjercicio),
                      subtitle: Text(
                        '${item.series} series x ${item.repeticiones} reps',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _terminar,
                  child: const Text('Terminar'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
