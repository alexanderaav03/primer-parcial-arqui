import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_detalle.dart';
import 'progreso_provider.dart';

/// Abre el bottom sheet para que el cliente registre que completó una
/// sesión de este ejercicio, precargado con los valores planeados.
Future<void> mostrarRegistrarProgresoSheet(
  BuildContext context, {
  required int rutinaId,
  required EjercicioDetalle ejercicio,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RegistrarProgresoSheet(rutinaId: rutinaId, ejercicio: ejercicio),
  );
}

class _RegistrarProgresoSheet extends ConsumerStatefulWidget {
  final int rutinaId;
  final EjercicioDetalle ejercicio;

  const _RegistrarProgresoSheet({required this.rutinaId, required this.ejercicio});

  @override
  ConsumerState<_RegistrarProgresoSheet> createState() => _RegistrarProgresoSheetState();
}

class _RegistrarProgresoSheetState extends ConsumerState<_RegistrarProgresoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repeticionesCtrl;
  late final TextEditingController _pesoCtrl;
  final _notaCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Precargados con lo PLANEADO como punto de partida -el cliente ajusta
    // si hizo distinto-.
    _seriesCtrl = TextEditingController(text: widget.ejercicio.series.toString());
    _repeticionesCtrl = TextEditingController(text: widget.ejercicio.repeticiones.toString());
    _pesoCtrl = TextEditingController(text: widget.ejercicio.peso.toString());
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repeticionesCtrl.dispose();
    _pesoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await crearRegistro(
        ref,
        rutinaId: widget.rutinaId,
        detalleId: widget.ejercicio.detalleId,
        seriesRealizadas: int.parse(_seriesCtrl.text.trim()),
        repeticionesRealizadas: int.parse(_repeticionesCtrl.text.trim()),
        pesoRealizado: num.parse(_pesoCtrl.text.trim()),
        nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      );

      // Refresca el badge de "sesiones registradas" en la card.
      ref.invalidate(
        registrosProgresoProvider((rutinaId: widget.rutinaId, detalleId: widget.ejercicio.detalleId)),
      );

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
    if (value == null || value.trim().isEmpty) return 'Requerido';
    return num.tryParse(value.trim()) == null ? 'Debe ser un número' : null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // viewInsets.bottom cubre el teclado; padding.bottom cubre la barra
        // de navegación del sistema (o el gesture bar) - sin este segundo
        // término el botón "Guardar" queda pegado a esa barra en
        // dispositivos con navegación por botones.
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.ejercicio.nombre, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Registra lo que hiciste realmente -puede ser distinto a lo planeado-.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seriesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Series realizadas'),
                      validator: _validarNumero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _repeticionesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Repeticiones realizadas'),
                      validator: _validarNumero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso realizado (kg)'),
                validator: _validarNumero,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notaCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _guardar,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
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
    );
  }
}
