import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'clientes_provider.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// TODO: ELIMINAR antes de entregar/producción - solo para pruebas rápidas
const _debugNombres = [
  'Pedro Gomez',
  'Sofia Rivera',
  'Diego Flores',
  'Valeria Ortiz',
  'Marco Aguilar',
];
const _debugObjetivos = [
  'Ganar masa muscular',
  'Perder grasa',
  'Mejorar resistencia',
  'Tonificar',
  'Rehabilitacion',
];
const _debugPassword = 'test1234';
final _debugRandom = Random();

class CrearClienteScreen extends ConsumerStatefulWidget {
  const CrearClienteScreen({super.key});

  @override
  ConsumerState<CrearClienteScreen> createState() => _CrearClienteScreenState();
}

class _CrearClienteScreenState extends ConsumerState<CrearClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureText = true;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _objetivoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await crearCliente(
        ref,
        nombre: _nombreCtrl.text.trim(),
        objetivo: _objetivoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Refresca la lista de ClientesScreen para que el nuevo cliente
      // aparezca sin salir y volver a entrar.
      ref.invalidate(clientesProvider);

      if (mounted) Navigator.of(context).pop();
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
    final nombre = _debugNombres[_debugRandom.nextInt(_debugNombres.length)];
    final objetivo = _debugObjetivos[_debugRandom.nextInt(_debugObjetivos.length)];
    final numero = _debugRandom.nextInt(90) + 10; // 2 digitos, para no repetir el email
    final emailBase = nombre.toLowerCase().replaceAll(' ', '.');

    setState(() {
      _nombreCtrl.text = nombre;
      _objetivoCtrl.text = objetivo;
      _emailCtrl.text = '$emailBase$numero@test.com';
      _passwordCtrl.text = _debugPassword;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo cliente')),
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
                          Text('Datos del cliente', style: Theme.of(context).textTheme.titleMedium),
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
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _objetivoCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Ingresa el objetivo' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa el email';
                          if (!_emailRegex.hasMatch(value.trim())) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Ingresa la contraseña' : null,
                        onFieldSubmitted: (_) => _submit(),
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
                            : const Text('Crear cliente'),
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
