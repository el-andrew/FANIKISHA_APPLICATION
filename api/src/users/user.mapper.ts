import type { User } from '../generated/prisma/client.js';

export interface UserDto {
  id: string;
  email: string;
  phone: string | null;
  /** True once the phone number was confirmed with an SMS code. */
  phoneVerified: boolean;
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
    phoneVerified: user.phoneVerifiedAt !== null,
    fullName: user.fullName,
    businessName: user.businessName,
    createdAt: user.createdAt.toISOString(),
  };
}
