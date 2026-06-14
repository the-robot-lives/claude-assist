const AUTHENTIK_BASE = "https://auth.derobot.is/application/o";
const CLIENT_ID = "DVWgHpiNA0WlFIhnjXUdJRlN9JLcw1rgQaCpIWxX";
const REDIRECT_URI =
  typeof window !== "undefined"
    ? `${window.location.origin}/auth/callback`
    : "https://noizu.com/auth/callback";
const SCOPES = "openid email profile";

function base64url(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode.apply(null, Array.from(new Uint8Array(buffer))))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generatePKCE() {
  const verifier = base64url(crypto.getRandomValues(new Uint8Array(32)).buffer);
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );
  const challenge = base64url(digest);
  return { verifier, challenge };
}

export async function startLogin() {
  const { verifier, challenge } = await generatePKCE();
  sessionStorage.setItem("pkce_verifier", verifier);

  const params = new URLSearchParams({
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    response_type: "code",
    scope: SCOPES,
    code_challenge: challenge,
    code_challenge_method: "S256",
  });

  window.location.href = `${AUTHENTIK_BASE}/authorize/?${params}`;
}

export async function handleCallback(code: string): Promise<boolean> {
  const verifier = sessionStorage.getItem("pkce_verifier");
  if (!verifier) return false;

  const res = await fetch(`${AUTHENTIK_BASE}/token/`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: CLIENT_ID,
      code,
      redirect_uri: REDIRECT_URI,
      code_verifier: verifier,
    }),
  });

  if (!res.ok) return false;

  const tokens = await res.json();
  sessionStorage.removeItem("pkce_verifier");
  localStorage.setItem("access_token", tokens.access_token);
  if (tokens.refresh_token)
    localStorage.setItem("refresh_token", tokens.refresh_token);
  if (tokens.id_token) localStorage.setItem("id_token", tokens.id_token);

  return true;
}

export function getUser(): { email?: string; name?: string } | null {
  const idToken = localStorage.getItem("id_token");
  if (!idToken) return null;
  try {
    const payload = JSON.parse(atob(idToken.split(".")[1]));
    return { email: payload.email, name: payload.name || payload.preferred_username };
  } catch {
    return null;
  }
}

export function isLoggedIn(): boolean {
  return !!localStorage.getItem("access_token");
}

export function logout() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("id_token");
  window.location.href = "/";
}
