import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/task.dart';
import 'tasks_view_model.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int? taskId;

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TasksViewModel>().findTask(taskId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tarea')),
      body: task == null
          ? const Center(child: Text('No se encontró esta tarea.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(task.description),
                const SizedBox(height: 16),
                Text('Prioridad: ${task.priority}'),
                Text(
                  task.isCompleted ? 'Estado: completada' : 'Estado: pendiente',
                ),
                Text('Usuario: ${task.userId}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<TasksViewModel>().toggleCompleted(task.id);
                  },
                  child: Text(
                    task.isCompleted
                        ? 'Marcar como pendiente'
                        : 'Marcar como completada',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _editTitle(context, task),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar título'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, task),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar tarea'),
                ),
              ],
            ),
    );
  }

  Future<void> _editTitle(BuildContext context, Task task) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditTitleDialog(initialTitle: task.title),
    );
    if (!context.mounted || newTitle == null) return;

    if (newTitle.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título debe tener al menos 3 caracteres.'),
        ),
      );
      return;
    }

    try {
      await context.read<TasksViewModel>().updateTask(
        task.copyWith(title: newTitle),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tarea actualizada')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la tarea')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar ${task.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<TasksViewModel>().deleteTask(task.id);
      if (context.mounted) context.pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la tarea')),
        );
      }
    }
  }
}

class _EditTitleDialog extends StatefulWidget {
  const _EditTitleDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_EditTitleDialog> createState() => _EditTitleDialogState();
}

class _EditTitleDialogState extends State<_EditTitleDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar título'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Título'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
