/** What the authentication guard attaches to each request. */
export interface AuthUser {
  id: string;
  email: string;
}

declare module '@nestjs/authentication' {
  interface AuthenticationTypes {
    user: AuthUser;
  }
}
