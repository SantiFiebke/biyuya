/// Centralized route definitions as enum.
enum AppRoute {
  login('login', '/login'),
  register('register', '/register'),
  onboarding('onboarding', '/onboarding'),
  verifyEmail('verify-email', '/verify-email'),
  splash('splash', '/splash'),
  home('home', '/home'),
  categories('categories', '/categories'),
  categoryNew('category-new', '/categories/new'),
  expenses('expenses', '/expenses'),
  expenseNew('expense-new', '/expenses/new'),
  reports('reports', '/reports'),
  profile('profile', '/profile');

  const AppRoute(this.name, this.path);

  final String name;
  final String path;

  // Parameterized route helpers
  static String categoryEdit(String id) => '/categories/$id/edit';
  static String expenseEdit(String id) => '/expenses/$id/edit';
  static String expenseDetail(String id) => '/expenses/$id';
}
