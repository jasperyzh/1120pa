import { createServerClient, parseCookieHeader } from "@supabase/ssr";

export function createSupabase(context: { cookies: { getAll(): any; set(name: string, value: string, options?: any): void }; request: { headers: { get(name: string): string | null } } }) {
  return createServerClient(
    import.meta.env.PUBLIC_SUPABASE_URL || "https://placeholder.supabase.co",
    import.meta.env.PUBLIC_SUPABASE_ANON_KEY || "placeholder",
    {
      cookies: {
        getAll() {
          return parseCookieHeader(context.request.headers.get("Cookie") ?? "");
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            context.cookies.set(name, value, options);
          });
        },
      },
    }
  );
}