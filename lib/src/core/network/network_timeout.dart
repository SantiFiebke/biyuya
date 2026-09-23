/// Shared timeout for Supabase network calls.
///
/// Offline, REST calls can hang until the OS TCP timeout (~30s). Bounding them
/// lets cache-fallback paths (e.g. `AuthRepositoryImpl.getUserProfile`) trigger
/// promptly instead of leaving the app stuck on the splash screen.
const kNetworkTimeout = Duration(seconds: 5);
