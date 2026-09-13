import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/date_format.dart';
import '../../core/widgets.dart';
import 'rutinas_provider.dart';

final _debugRandom = Random();

class CrearRutinaScreen extends ConsumerStatefulWidget {
  final int clienteId;

  const CrearRutinaScreen({super.key, required this.clienteId});

  @override
  ConsumerState<CrearRutinaScreen> createState() => _CrearRutinaScreenState();
}

class _CrearRutinaScreenState extends ConsumerState<CrearRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _loading = false;
  String? _error;

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
        // Si la fecha fin ya elegida quedó inválida con el nuevo inicio, se pide de nuevo.
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
      final rutina = await crearRutina(
        ref,
        clienteId: widget.clienteId,
        nombre: _nombreCtrl.text.trim(),
        fechaInicio: formatFechaIso(_fechaInicio!),
        fechaFin: formatFechaIso(_fechaFin!),
      );

      // Se reemplaza esta pantalla (no se apila) para que, al terminar de
      // agregar ejercicios, "volver" lleve directo a la lista de rutinas.
      if (mounted) {
        context.pushReplacement('/rutinas/${rutina.id}/agregar-ejercicios?clienteId=${widget.clienteId}');
      }
    } on DioException catch (e) {
      setState(() => _error = friendlyMessage(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // TODO: ELIMINAR antes de entregar/producción - solo para pruebas rápidas
  void _autorrellenar() {
    final numero = _debugRandom.nextInt(20) + 1;
    final hoy = DateTime.now();
    setState(() {
      _nombreCtrl.text = 'Rutina Semana $numero';
      _fechaInicio = hoy;
      _fechaFin = hoy.add(const Duration(days: 6));
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva rutina')),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Datos de la rutina', style: Theme.of(context).textTheme.titleMedium),
                          // TODO: ELIMINAR antes de entregar/producción - solo para pruebas rápidas
                          TextButton.icon(
                            onPressed: _autorrellenar,
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Autorrellenar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            : const Text('Crear rutina'),
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
