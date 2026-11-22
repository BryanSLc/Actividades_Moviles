import '../domain/task.dart';
import 'local_task_repository.dart';
import 'task_api_service.dart';
import 'task_repository.dart';

class CombinedTaskRepository implements TaskRepository {
  CombinedTaskRepository(this._local, this._apiService);

  static const int remoteIdOffset = 1000;

  final LocalTaskRepository _local;
  final TaskApiService _apiService;
  List<Task> _tasks = [];

  @override
  Future<List<Task>> getTasks() async {
    final localTasks = await _local.getTasks();
    final remoteTasks = await _apiService.getTasks();

    final shiftedRemote = remoteTasks.map(
      (task) => Task(
        id: task.id + remoteIdOffset,
        title: task.title,
        description: task.description,
        priority: task.priority,
        isCompleted: task.isCompleted,
        userId: task.userId,
      ),
    );

    _tasks = [...localTasks, ...shiftedRemote];
    return List.unmodifiable(_tasks);
  }

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }
}
