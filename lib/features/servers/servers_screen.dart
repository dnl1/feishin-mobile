import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/server.dart';
import '../auth/auth_controller.dart';

/// Saved server list: pick the active one, remove, or add a new one.
class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover ${server.name}?'),
        content: const Text(
          'As credenciais salvas para este servidor também serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).deleteServer(server.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Servidores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/servers/add'),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: switch (auth) {
        AsyncData(:final value) when value.servers.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Nenhum servidor configurado.\n'
              'Adicione seu servidor Navidrome para começar.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => ListView(
          children: [
            for (final server in value.servers)
              ListTile(
                leading: Icon(
                  server.id == value.currentServerId
                      ? Icons.check_circle
                      : Icons.dns_outlined,
                  color: server.id == value.currentServerId
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(server.name),
                subtitle: Text('${server.url} · ${server.username}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, server),
                ),
                onTap: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .setCurrentServer(server.id);
                  if (context.mounted) {
                    context.go('/');
                  }
                },
              ),
          ],
        ),
        AsyncError(:final error) => Center(child: Text('Erro: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
