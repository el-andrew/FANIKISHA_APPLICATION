import { Injectable } from '@nestjs/common';
import {
  AuthenticationStorage,
  type RefreshTokenRecord,
  type RefreshTokenStore,
} from '@nestjs/authentication';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

/**
 * Revocation markers older than the longest a family can live (90 days, see
 * the `refreshToken.absoluteTtl` option) protect nothing and are deleted.
 */
const REVOCATION_RETENTION_MS = 91 * 24 * 60 * 60 * 1000;

/**
 * Stores @nestjs/authentication's refresh tokens in PostgreSQL. Checked
 * against the package's storage contract in `test/refresh-token.store.e2e-spec.ts`.
 */
@Injectable()
export class PrismaRefreshTokenStore implements RefreshTokenStore {
  constructor(
    private readonly prisma: PrismaService,
    storage: AuthenticationStorage,
  ) {
    storage.registerSource({ refreshTokens: this });
  }

  async getRefreshToken(id: string): Promise<RefreshTokenRecord | undefined> {
    const row = await this.prisma.refreshToken.findUnique({ where: { id } });
    if (!row) return undefined;
    return {
      id: row.id,
      familyId: row.familyId,
      userId: row.userId,
      createdAt: row.createdAt,
      expiresAt: row.expiresAt,
      familyExpiresAt: row.familyExpiresAt,
      ...(row.usedAt ? { usedAt: row.usedAt } : {}),
      ...(row.claims !== null
        ? { claims: row.claims as Record<string, unknown> }
        : {}),
    };
  }

  async saveRefreshToken(record: RefreshTokenRecord): Promise<void> {
    await this.prisma.$transaction([
      // Keep the table bounded: families past their absolute lifetime can
      // never be used again.
      this.prisma.refreshToken.deleteMany({
        where: { familyExpiresAt: { lt: record.createdAt } },
      }),
      this.prisma.revokedRefreshTokenFamily.deleteMany({
        where: {
          revokedAt: { lt: new Date(Date.now() - REVOCATION_RETENTION_MS) },
        },
      }),
      this.prisma.refreshToken.create({
        data: {
          id: record.id,
          familyId: record.familyId,
          userId: record.userId,
          createdAt: record.createdAt,
          expiresAt: record.expiresAt,
          familyExpiresAt: record.familyExpiresAt,
          usedAt: record.usedAt,
          claims: record.claims as Prisma.InputJsonValue | undefined,
        },
      }),
    ]);
  }

  async markRefreshTokenUsed(id: string, at: Date): Promise<boolean> {
    // One conditional UPDATE: of several concurrent calls, exactly one wins.
    const { count } = await this.prisma.refreshToken.updateMany({
      where: { id, usedAt: null },
      data: { usedAt: at },
    });
    return count === 1;
  }

  async revokeRefreshTokenFamily(familyId: string): Promise<void> {
    await this.prisma.revokedRefreshTokenFamily.createMany({
      data: [{ familyId }],
      skipDuplicates: true,
    });
  }

  async isRefreshTokenFamilyRevoked(familyId: string): Promise<boolean> {
    const row = await this.prisma.revokedRefreshTokenFamily.findUnique({
      where: { familyId },
      select: { familyId: true },
    });
    return row !== null;
  }

  async revokeUserRefreshTokens(userId: string): Promise<void> {
    await this.prisma.$executeRaw`
      INSERT INTO revoked_refresh_token_families (family_id)
      SELECT DISTINCT family_id FROM refresh_tokens WHERE user_id = ${userId}
      ON CONFLICT (family_id) DO NOTHING`;
  }
}
