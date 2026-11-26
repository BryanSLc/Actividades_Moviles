import '../domain/task.dart';
import 'local_task_repository.dart';
import 'task_api_service.dart';
import 'task_repository.dart';

/// Une las tareas propias con las de la API.
/// Las tareas de la API llevan el id desplazado en [remoteIdOffset].
class CombinedTaskRepository implements TaskRepository {
  CombinedTaskRepository(this._local, this._apiService);

  static const int remoteIdOffset = 1000;

  final LocalTaskRepository _local;
  final TaskApiService _apiService;
  List<Task> _tasks = [];

  bool _isRemote(int id) => id >= remoteIdOffset;

  Task _withId(Task task, int id) {
    return Task(
      id: id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      isCompleted: task.isCompleted,
      userId: task.userId,
    );
  }

  @override
  Future<List<Task>> getTasks() async {
    final localTasks = await _local.getTasks();
    final remoteTasks = await _apiService.getTasks();
    final shiftedRemote = remoteTasks.map(
      (task) => _withId(task, task.id + remoteIdOffset),
    );

    _tasks = [...localTasks, ...shiftedRemote];
    return List.unmodifiable(_tasks);
  }

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    if (!_isRemote(task.id)) _local.save(task);
  }

  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    // POST simulado: la API responde 201 pero no guarda la tarea.
    await _apiService.createTask(title);
    // La tarea se conserva en el repositorio local mientras la app esté abierta.
    final task = await _local.createTask(title, description, priority);
    _tasks = [task, ..._tasks];
    return task;
  }

  @override
  Future<void> updateTask(Task task) async {
    if (_isRemote(task.id)) {
      await _apiService.updateTask(_withId(task, task.id - remoteIdOffset));
    }
    save(task);
  }

  @override
  Future<void> deleteTask(int id) async {
    if (_isRemote(id)) {
      await _apiService.deleteTask(id - remoteIdOffset);
    } else {
      await _local.deleteTask(id);
    }
    _tasks = _tasks.where((task) => task.id != id).toList();
  }
}
