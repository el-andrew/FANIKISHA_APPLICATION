import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Public } from '@nestjs/authentication';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import { z } from 'zod';
import { emailSchema } from '../auth/auth.schemas.js';
import type { Env } from '../config/env.js';
import { UsersService } from '../users/users.service.js';
import {
  deletionDone,
  deletionForm,
  deletionTitle,
} from './account-deletion.js';
import { page, type PageLanguage } from './html.js';
import { LEGAL_UPDATED, type Operator } from './operator.js';
import { privacyPolicy } from './privacy.js';
import { termsOfService } from './terms.js';

const langSchema = z.object({
  lang: z.enum(['en', 'sw']).catch('en').default('en'),
});

const deletionFormSchema = z.object({
  lang: z.enum(['en', 'sw']).catch('en').default('en'),
  email: z.string().default(''),
  password: z.string().default(''),
});

/**
 * Public web pages: the privacy policy, terms of service, and a page to
 * delete an account without the app (Google Play requires all three).
 */
@Public()
@Controller()
export class LegalController {
  private readonly operator: Operator;

  constructor(
    private readonly users: UsersService,
    config: ConfigService<Env, true>,
  ) {
    this.operator = {
      name: config.get('OPERATOR_NAME', { infer: true }),
      registration: config.get('OPERATOR_REGISTRATION', { infer: true }),
      address: config.get('OPERATOR_ADDRESS', { infer: true }),
      email: config.get('OPERATOR_EMAIL', { infer: true }),
    };
  }

  @Get('privacy')
  @SkipThrottle()
  @Header('Content-Type', 'text/html; charset=utf-8')
  privacy(@Query({ schema: langSchema }) { lang }: { lang: PageLanguage }) {
    return page({
      title: lang === 'sw' ? 'Sera ya faragha' : 'Privacy policy',
      lang,
      path: '/privacy',
      updated: LEGAL_UPDATED,
      body: privacyPolicy(lang, this.operator),
    });
  }

  @Get('terms')
  @SkipThrottle()
  @Header('Content-Type', 'text/html; charset=utf-8')
  terms(@Query({ schema: langSchema }) { lang }: { lang: PageLanguage }) {
    return page({
      title: lang === 'sw' ? 'Masharti ya huduma' : 'Terms of service',
      lang,
      path: '/terms',
      updated: LEGAL_UPDATED,
      body: termsOfService(lang, this.operator),
    });
  }

  @Get('account-deletion')
  @Header('Content-Type', 'text/html; charset=utf-8')
  deletionPage(
    @Query({ schema: langSchema }) { lang }: { lang: PageLanguage },
  ) {
    return page({
      title: deletionTitle(lang),
      lang,
      path: '/account-deletion',
      body: deletionForm(lang, this.operator),
    });
  }

  /** Deletes the account whose email and password are entered. */
  @Post('account-deletion')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Header('Content-Type', 'text/html; charset=utf-8')
  async deleteFromWeb(
    @Body({ schema: deletionFormSchema })
    form: z.infer<typeof deletionFormSchema>,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { lang } = form;
    const email = emailSchema.safeParse(form.email);
    if (!email.success || !form.password) {
      res.status(HttpStatus.BAD_REQUEST);
      return this.formPage(lang, 'invalid', form.email);
    }
    const deleted = await this.users.deleteAccountWithCredentials(
      email.data,
      form.password,
    );
    if (!deleted) {
      res.status(HttpStatus.UNAUTHORIZED);
      return this.formPage(lang, 'wrong', form.email);
    }
    return page({
      title: deletionTitle(lang, true),
      lang,
      path: '/account-deletion',
      body: deletionDone(lang),
    });
  }

  private formPage(
    lang: PageLanguage,
    error: 'wrong' | 'invalid',
    email: string,
  ) {
    return page({
      title: deletionTitle(lang),
      lang,
      path: '/account-deletion',
      body: deletionForm(lang, this.operator, { error, email }),
    });
  }
}
