// Elimina la cuenta del usuario autenticado (requisito de Google Play:
// eliminación de cuenta dentro de la app).
//
// Deploy: supabase functions deploy delete-account
//
// No se hardcodean secretos: SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los
// inyecta Supabase en runtime.
import { createClient } from "npm:@supabase/supabase-js@2";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  try {
    const authHeader = request.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Falta el token de autenticación" }, 401);
    }
    const jwt = authHeader.replace("Bearer ", "");

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Valida el JWT del caller contra Supabase Auth.
    const { data, error } = await admin.auth.getUser(jwt);
    if (error || !data?.user) {
      return json({ error: "Usuario inválido" }, 401);
    }

    // Borra el usuario de auth.users; el CASCADE limpia profiles y
    // user_settings, y expenses.user_uuid queda en NULL.
    const { error: deleteError } = await admin.auth.admin.deleteUser(
      data.user.id,
    );
    if (deleteError) {
      return json({ error: deleteError.message }, 500);
    }

    return json({ ok: true }, 200);
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : "Error interno" },
      500,
    );
  }
});
