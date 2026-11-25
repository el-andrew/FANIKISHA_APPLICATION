import { Injectable } from '@nestjs/common';
import {
  AuthenticationRegistry,
  JwtBearerProvider,
  type JwtClaims,
} from '@nestjs/authentication';
import { z } from 'zod';
import { PrismaService } from '../prisma/prisma.service.js';
import type { AuthUser } from './auth.types.js';

const subjectSchema = z.uuid();

/**
 * Accepts `Authorization: Bearer <access token>` on every route not marked
 * `@Public()`. The token is verified with the module's `accessToken` options;
 * the user is then loaded so deleted accounts are rejected straight away.
 */
@Injectable()
export class JwtAuthProvider extends JwtBearerProvider<AuthUser> {
  constructor(
    private readonly prisma: PrismaService,
    registry: AuthenticationRegistry,
  ) {
    super();
    registry.registerProvider(this);
  }

  protected async validate(claims: JwtClaims): Promise<AuthUser | null> {
    const subject = subjectSchema.safeParse(claims.sub);
    if (!subject.success) return null;
    return this.prisma.user.findUnique({
      where: { id: subject.data },
      select: { id: true, email: true },
    });
  }
}
