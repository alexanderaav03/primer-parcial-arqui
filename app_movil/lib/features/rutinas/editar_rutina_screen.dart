import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/date_format.dart';
import '../../core/widgets.dart';
import '../models/ejercicio_detalle.dart';
import 'rutinas_provider.dart';

class EditarRutinaScreen extends ConsumerStatefulWidget {
  final RutinaDetalle rutina;

  const EditarRutinaScreen({super.key, required this.rutina});

  @override
  ConsumerState<EditarRutinaScreen> createState() => _EditarRutinaScreenState();
}

class _EditarRutinaScreenState extends ConsumerState<EditarRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;

  late DateTime? _fechaInicio;
  late DateTime? _fechaFin;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.rutina.nombre);
    _fechaInicio = DateTime.tryParse(widget.rutina.fechaInicio);
    _fechaFin = DateTime.tryParse(widget.rutina.fechaFin);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final primerDiaValido = esInicio ? DateTime(2020) : (_fechaInicio ?? DateTime(2020));
    var inicial = (esInicio ? _fechaInicio : _fechaFin) ?? DateTime.now();
    if (inicial.isBefore(primerDiaValido)) inicial = primerDiaValido;

    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primerDiaValido,
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;

    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
        if (_fechaFin != null && !_fechaFin!.isAfter(elegida)) {
          _fechaFin = null;
        }
      } else {
        _fechaFin = elegida;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _error = 'Selecciona la fecha de inicio y la fecha de fin');
      return;
    }
    if (!_fechaFin!.isAfter(_fechaInicio!)) {
      setState(() => _error = 'La fecha fin debe ser posterior a la fecha inicio');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await editarRutina(
        ref,
        rutinaId: widget.rutina.id,
        nombre: _nombreCtrl.text.trim(),
        fechaInicio: formatFechaIso(_fechaInicio!),
        fechaFin: formatFechaIso(_fechaFin!),
      );

      // Refresca el detalle y la lista de rutinas del cliente.
      ref.invalidate(rutinaDetalleProvider(widget.rutina.id));
      ref.invalidate(rutinasProvider(widget.rutina.clienteId));

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
      appBar: AppBar(title: const Text('Editar rutina')),
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
                      Text('Datos de la rutina', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la rutina',
                          prefixIcon: Icon(Icons.event_note_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      DateField(
                        label: 'Fecha inicio',
                        fecha: _fechaInicio,
                        onTap: () => _elegirFecha(esInicio: true),
                      ),
                      const SizedBox(height: 16),
                      DateField(
                        label: 'Fecha fin',
                        fecha: _fechaFin,
                        onTap: () => _elegirFecha(esInicio: false),
                      ),
                      const SizedBox(height: 24),
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
