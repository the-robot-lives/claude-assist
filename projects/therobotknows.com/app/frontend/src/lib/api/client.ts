import { getApiBaseUrl } from "./config";
import { ApiError, fieldErrorsFromBody, messageFromBody } from "./errors";

let refreshPromise: Promise<string | null> | null = null;

function apiUrl(): string {
  return getApiBaseUrl();
}

async function attemptRefresh(): Promise<string | null> {
  if (typeof window === "undefined") return null;
  const refreshToken = localStorage.getItem("refresh_token");
  if (!refreshToken) return null;

  try {
    const res = await fetch(`${apiUrl()}/api/v1/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (data.access_token) {
      localStorage.setItem("access_token", data.access_token);
      if (data.refresh_token) {
        localStorage.setItem("refresh_token", data.refresh_token);
      }
      return data.access_token as string;
    }
    return null;
  } catch {
    return null;
  }
}

export type RequestOptions = RequestInit & {
  /** Skip Authorization header (public endpoints). */
  skipAuth?: boolean;
};

/**
 * Typed fetch wrapper: Bearer attach, single-flight refresh on 401, error envelope.
 */
export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { skipAuth, ...init } = options;
  const token =
    !skipAuth && typeof window !== "undefined"
      ? localStorage.getItem("access_token")
      : null;

  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...init.headers,
  };

  const res = await fetch(`${apiUrl()}${path}`, { ...init, headers });

  if (res.status === 401 && token && !path.includes("/auth/refresh")) {
    if (!refreshPromise) {
      refreshPromise = attemptRefresh().finally(() => {
        refreshPromise = null;
      });
    }
    const newToken = await refreshPromise;
    if (newToken) {
      const retryRes = await fetch(`${apiUrl()}${path}`, {
        ...init,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${newToken}`,
          ...init.headers,
        },
      });
      if (!retryRes.ok) {
        const body = await retryRes.json().catch(() => ({}));
        throw new ApiError(
          messageFromBody(body, `Request failed: ${retryRes.status}`),
          retryRes.status,
          fieldErrorsFromBody(body),
        );
      }
      if (retryRes.status === 204) return undefined as T;
      return retryRes.json() as Promise<T>;
    }

    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    }
    throw new ApiError("Unauthorized", 401);
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new ApiError(
      messageFromBody(body, `Request failed: ${res.status}`),
      res.status,
      fieldErrorsFromBody(body),
    );
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}
