import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

/// Login form — adding a server IS logging in, same as the original login
/// feature (src/renderer/features/login/, servers/).
class AddServerScreen extends ConsumerStatefulWidget {
  const AddServerScreen({super.key});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _savePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .addServer(
            name: _nameController.text.trim().isEmpty
                ? Uri.parse(_urlController.text.trim()).host
                : _nameController.text.trim(),
            url: _urlController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            savePassword: _savePassword,
          );

      if (mounted) {
        context.go('/');
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao conectar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar servidor')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _urlController,
                autocorrect: false,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'URL do servidor',
                  hintText: 'https://musica.exemplo.com',
                ),
                validator: (value) {
                  final url = Uri.tryParse(value?.trim() ?? '');
                  if (url == null || !url.hasScheme || url.host.isEmpty) {
                    return 'Informe a URL completa (com http:// ou https://)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome (opcional)',
                  hintText: 'Minha biblioteca',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Usuário'),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Informe o usuário' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Senha'),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Salvar senha'),
                subtitle: const Text(
                  'Permite reconectar automaticamente quando a sessão expirar',
                ),
                value: _savePassword,
                onChanged: (value) => setState(() => _savePassword = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Conectar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
