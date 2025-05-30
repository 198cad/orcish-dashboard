// lib/mock-auth.ts
import { setCookie, deleteCookie } from "cookies-next";

const MOCK_USER = {
  email: "user@example.com",
  password: "password123",
  sessionToken: "mock_session_token_123",
};

export async function mockLogin(email: string, password: string): Promise<boolean> {
  return new Promise((resolve) => {
    setTimeout(() => {
      if (email === MOCK_USER.email && password === MOCK_USER.password) {
        // Simulate setting a session cookie
        setCookie("session_token", MOCK_USER.sessionToken, { maxAge: 60 * 60 * 24, path: "/" });
        console.log("Mock login successful");
        resolve(true);
      } else {
        console.log("Mock login failed: Invalid credentials");
        resolve(false);
      }
    }, 500); // Simulate network delay
  });
}

export async function mockLogout(): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(() => {
      // Simulate deleting the session cookie
      deleteCookie("session_token", { path: "/" });
      console.log("Mock logout successful");
      resolve();
    }, 300); // Simulate network delay
  });
}
