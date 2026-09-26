/// Centralized route definitions as enum.
enum AppRoute {
  login('login', '/login'),
  register('register', '/register'),
  onboarding('onboarding', '/onboarding'),
  // Ruta deshabilitada a propósito: la confirmación de email está OFF en
  // Supabase (Authentication > Settings > "Confirm email" desactivado), así
  // que nunca hay una pantalla de verificación que servir.
  // Para rehabilitar: 1) activar "Confirm email" en Supabase, 2) crear la
  // vista VerifyEmailView + su GoRoute en router_provider.dart,
  // 3) descomentar esta línea y 4) descomentar el guard `isVerifyingEmail`
  // del redirect en router_provider.dart.
  // verifyEmail('verify-email', '/verify-email'),
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
