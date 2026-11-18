import type { User } from '../generated/prisma/client.js';

export interface UserDto {
  id: string;
  email: string;
  phone: string | null;
  fullName: string;
  businessName: string | null;
  createdAt: string;
}

/** The public shape of a user. Never includes the password hash. */
export function toUserDto(user: User): UserDto {
  return {
    id: user.id,
    email: user.email,
    phone: user.phone,
    fullName: user.fullName,
    businessName: user.businessName,
    createdAt: user.createdAt.toISOString(),
  };
}
