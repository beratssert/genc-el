class ApiUrl {
  static const String baseUrl =
      'http://10.0.2.2:8080'; // Common local dev URL for Android emulator, change as needed

  //Auth
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String changePassword = '/api/v1/auth/change-password';

  //User Management
  /// POST - add new user
  /// GET - get all users (with filters)
  /// GET - get user by id /{id}
  /// PUT - update user /{id}
  /// DELETE - delete user /{id}
  /// GET - get user history /{id}/history

  static const String users = '/api/v1/users';

  // Task
  /// POST - create task
  /// *body* {"shopping_list": [...], "notes": "..."}
  static const String tasks = '/api/v1/tasks';

  /// GET - get current active task of the user
  static const String myActiveTask = '/api/v1/tasks/my-active-task';

  /// PUT - update task /{id}
  static const String updateTask = '/api/v1/tasks/{id}/accept';

  /// PUT - start shopping /{id}
  /// body {"received_amount":100.0}
  static const String startShopping = '/api/v1/tasks/{id}/start-shopping';

  /// PUT - complete shopping /{id}
  /// Multipart File: receipt image
  static const String completeShopping = '/api/v1/tasks/{id}/complete-shopping';

  /// PUT - complete task /{id}
  /// body {"change_amount":10.0,"note":"..."}
  static const String completeTask = '/api/v1/tasks/{id}/complete';

  /// PUT - confirm start /{id}
  static const String confirmStart = '/api/v1/tasks/{id}/confirm-start';

  /// PUT - confirm end /{id}
  static const String confirmEnd = '/api/v1/tasks/{id}/confirm-end';

  // Institutions and Bursary

  /// GET - get my stats
  static const String myStats = '/api/v1/institutions/my-stats';

  /// GET - get bursaries
  static const String bursaries = '/api/v1/bursaries';

  /// POST - calculate bursaries
  static const String calculateBursaries = '/api/v1/bursaries/calculate';

  /// PUT - pay bursary /{id}
  static const String payBursary = '/api/v1/bursaries/{id}/pay';
}
