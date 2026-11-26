# taskflow

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## Alcance de TaskFlow

Problema: necesito organizar actividades académicas y saber cuáles faltan.
Usuario objetivo: estudiante que planifica entregas semanales.

### Historias de usuario y criterios de aceptación
1. Como estudiante, quiero listar mis tareas para ver qué debo hacer.
   Criterio: la lista muestra título, prioridad y estado de cada tarea.
2. Como estudiante, quiero abrir una tarea para leer su descripción.
   Criterio: al tocar una tarjeta aparece el detalle de la tarea elegida.
3. Como estudiante, quiero crear una tarea para registrar un pendiente.
   Criterio: el formulario guarda una tarea válida y la lista la muestra.
4. Como estudiante, quiero editar una tarea para corregir sus datos.
   Criterio: los cambios guardados aparecen en lista y detalle.
5. Como estudiante, quiero eliminar una tarea terminada para limpiar la lista.
   Criterio: después de confirmar, la tarea desaparece de la lista.

### Modelo de datos
Task: id (entero único), title (texto), description (texto),
priority (Alta, Media o Baja), isCompleted (verdadero/falso),
userId (entero que identifica al usuario de prueba).

### Tareas de ejemplo
1. Analizar requerimientos (Alta, pendiente)
2. Diseñar bocetos de pantallas (Media, pendiente)
3. Documentar cronograma de trabajo y flujo de trabajo (Alta, completada)
4. Organizar el backlog (Alta, pendiente)
5. Revisar código (Media, pendiente)

### Pantallas previstas
Lista: tarjetas de tareas y acción para crear.
Detalle: información completa y futuras acciones de editar o eliminar.
Formulario: campos de título, descripción y prioridad.

### Requisitos no funcionales
La navegación debe tener textos comprensibles.
Un id inexistente debe mostrar un mensaje en vez de cerrar la app.

### Contrato de API que necesitaremos
GET /tasks         listar tareas
GET /tasks/:id     consultar detalle
POST /tasks        crear tarea
PATCH /tasks/:id   actualizar tarea
DELETE /tasks/:id  eliminar tarea

La API concreta se elegirá después. Estas rutas son requisitos, no
direcciones de un servidor ya conectado.

TaskFlow muestra primero mis ocho tareas locales y, a continuación, las
tareas obtenidas de la API. A los ids remotos se les suma 1000 para que no
coincidan con los ids locales. Las tareas locales se definen en
LocalTaskRepository y las remotas se consultan con TaskApiService.
CombinedTaskRepository las une en una sola lista.


## Estados de la lista de tareas

La pantalla de tareas distingue cuatro situaciones. Todas se controlan desde
TasksViewModel, que avisa a la vista con notifyListeners.

- Carga: mientras se espera la respuesta, se muestra un indicador circular.
  Se activa con isLoading = true y evita lanzar dos consultas a la vez.
- Éxito: la respuesta contiene tareas y se dibuja una tarjeta por cada Task.
- Vacío: la consulta terminó bien pero la lista tiene cero tareas. Se muestra
  "Todavía no hay tareas para mostrar." y el botón Actualizar.
- Error: la consulta falló (red, servidor o formato). Se muestra "No se
  pudieron cargar las tareas." y el botón Reintentar. La excepción técnica
  se escribe solo en la consola.

Vacío y error son distintos: una lista vacía es una respuesta válida, y un
error significa que no sabemos qué tareas hay.

### Cómo provoqué cada estado
- Carga: limité la red a "Slow 4G" en las herramientas de Chrome (F12, pestaña
  Network) y actualicé la lista.
- Éxito: con internet, la lista muestra mis ocho tareas locales y las de la
  API del usuario 1.
- Error: con la app abierta, apagué el wifi y pulsé el ícono de actualizar.
- Reintento: encendí el wifi y pulsé Reintentar; la lista volvió sin
  reiniciar la aplicación.
- Vacío: cambié temporalmente TaskApiService.userId a 9999 y usé solo
  RemoteTaskRepository, porque ese usuario no tiene tareas. Después restauré
  userId = 1 y el repositorio combinado.

Limitación: marcar una tarea como completada solo cambia la copia en memoria.
Al actualizar, la lista se vuelve a pedir y esa marca se pierde. La
persistencia de cambios se estudiará en las sesiones de CRUD.



## Formulario de tareas

TaskFlow incluye una pantalla "Nueva tarea" (ruta /new), accesible desde el
botón flotante de la lista. El formulario valida los datos antes de preparar
una tarea nueva.

### Campos y validaciones
- Título: obligatorio, mínimo 3 caracteres. Mensajes: "Escribe un título para
  la tarea." y "El título debe tener al menos 3 caracteres."
- Descripción: obligatoria, mínimo 5 caracteres. Mensajes: "Describe
  brevemente la tarea." y "La descripción debe tener al menos 5 caracteres."
- Prioridad: lista desplegable con Alta, Media y Baja (por defecto Media).
- Fecha límite: opcional, se elige con showDatePicker. No se exige para
  guardar y se puede quitar.

### Cómo funciona
Form agrupa los campos y GlobalKey<FormState> permite llamar a validate()
antes de guardar. Cada TextFormField tiene un validator que devuelve un
mensaje si el dato es inválido y null si es válido. Los
TextEditingController permiten leer el texto y se liberan en dispose().
Al guardar, el formulario devuelve un TaskDraft a la lista con context.pop,
y la lista muestra un mensaje. Cancelar regresa sin mensaje.

Limitación: el formulario todavía no envía datos a la API ni agrega la tarea
a la lista. El mensaje verifica el retorno del borrador y no representa una
creación remota. La conexión con POST se hará en la sesión 10.


## CRUD de tareas (POST, PATCH y DELETE)

TaskFlow envía cambios a JSONPlaceholder y actualiza la lista solo después de
recibir una respuesta correcta.

### Operaciones
- Crear (POST /todos): el formulario "Nueva tarea" llama a createTask. La API
  responde HTTP 201. Se envían title, completed y userId.
- Editar (PATCH /todos/{id}): el botón "Editar título" del detalle abre un
  diálogo. Se envían title y completed. La API responde HTTP 200.
- Eliminar (DELETE /todos/{id}): el botón "Eliminar tarea" pide confirmación
  antes de llamar a deleteTask. La API responde HTTP 200.

### Flujo de cada operación
Pantalla -> TasksViewModel -> TaskRepository -> TaskApiService -> API.
El ViewModel espera la respuesta con await y solo después modifica su lista y
avisa con notifyListeners. Si la petición falla, se muestra un SnackBar de
error y no se muestra mensaje de éxito.

### Tareas locales y tareas de la API
Mis tareas propias (ids locales) no existen en el servidor, por lo que sus
cambios solo se guardan en memoria. Las tareas de la API (id desplazado en
1000) sí envían PATCH y DELETE con su id real. Al crear una tarea se envía el
POST, pero la tarea se conserva en el repositorio local porque la API no la
guarda.

### JSONPlaceholder simula las escrituras
La API responde como si hubiera guardado el cambio, pero no lo persiste. Al
actualizar la lista, los cambios hechos a tareas de la API vuelven a su valor
original. La descripción, la prioridad y la fecha límite del formulario no se
envían, porque la API solo conoce title, completed y userId.