import '../domain/task.dart';
import 'task_repository.dart';

class LocalTaskRepository implements TaskRepository {
  final List<Task> _tasks = [
    const Task(
      id: 1,
      title: 'Analizar requerimientos',
      description: 'Revisar entrevistas',
      priority: 'Alta',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 2,
      title: 'Diseñar bocetos de pantallas',
      description: 'Revisar los requerimientos',
      priority: 'Media',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 3,
      title: 'Documentar cronograma de trabajo y flujo de trabajo',
      description: 'Planificar un horario de trabajo y actividades',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    const Task(
      id: 4,
      title: 'Organizar el backlog',
      description: 'Priorizar pendientes',
      priority: 'Alta',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 5,
      title: 'Revisar código',
      description: 'Ejecutar flutter analyze',
      priority: 'Media',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 6,
      title: 'Implementar la navegación',
      description: 'Configurar go_router y las rutas de lista y detalle',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    const Task(
      id: 7,
      title: 'Conectar la app a una API',
      description: 'Consultar las tareas con Dio y convertir el JSON',
      priority: 'Media',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 8,
      title: 'Preparar la presentación final',
      description: 'Armar las diapositivas y practicar la demostración',
      priority: 'Baja',
      isCompleted: false,
      userId: 1,
    ),
  ];

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(_tasks);

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }

  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    final nextId = _tasks.isEmpty
        ? 1
        : _tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
    final task = Task(
      id: nextId,
      title: title,
      description: description,
      priority: priority,
      isCompleted: false,
      userId: 1,
    );
    _tasks.insert(0, task);
    return task;
  }

  @override
  Future<void> updateTask(Task task) async => save(task);

  @override
  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
  }
}
