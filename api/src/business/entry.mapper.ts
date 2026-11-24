import type { BusinessEntry, EntryType } from '../generated/prisma/client.js';
import { toDateOnly } from '../common/dates.js';
import { toAmount } from '../common/money.js';

export interface EntryDto {
  id: string;
  type: EntryType;
  amount: number;
  category: string | null;
  note: string | null;
  /** YYYY-MM-DD, the business day it happened on. */
  occurredOn: string;
  createdAt: string;
}

export function toEntryDto(entry: BusinessEntry): EntryDto {
  return {
    id: entry.id,
    type: entry.type,
    amount: toAmount(entry.amount),
    category: entry.category,
    note: entry.note,
    occurredOn: toDateOnly(entry.occurredOn),
    createdAt: entry.createdAt.toISOString(),
  };
}
