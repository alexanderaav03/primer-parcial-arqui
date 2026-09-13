import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/cliente.dart';
import 'clientes_provider.dart';

/// Mismo formulario visual de CrearClienteScreen, pero solo con Nombre y
/// Objetivo -email/password quedan fuera de alcance, se editarían junto
/// con lógica de autenticación/reset de contraseña más adelante-.
class EditarClienteScreen extends ConsumerStatefulWidget {
  final Cliente cliente;

  const EditarClienteScreen({super.key, required this.cliente});

  @override
  ConsumerState<EditarClienteScreen> createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends ConsumerState<EditarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _objetivoCtrl;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cliente.nombre);
    _objetivoCtrl = TextEditingController(text: widget.cliente.objetivo);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await editarCliente(
        ref,
        clienteId: widget.cliente.id,
        nombre: _nombreCtrl.text.trim(),
        objetivo: _objetivoCtrl.text.trim(),
      );

      // Refresca la lista de ClientesScreen para que se vean los cambios.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar cliente')),
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
                      Text('Datos del cliente', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
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
