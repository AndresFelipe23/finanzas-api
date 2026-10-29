import { Controller, Get, Headers, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiExcludeController } from '@nestjs/swagger';
import { timingSafeEqual } from 'crypto';
import { PagosRecurrentesScheduler } from './pagos-recurrentes.scheduler';

/**
 * Rutas que dispara Vercel Cron (vercel.json). En serverless no hay un
 * proceso permanente para el intervalo del scheduler, así que Vercel llama
 * aquí una vez al día con `Authorization: Bearer <CRON_SECRET>`.
 */
@ApiExcludeController()
@Controller('cron')
export class CronController {
  constructor(
    private readonly scheduler: PagosRecurrentesScheduler,
    private readonly config: ConfigService,
  ) {}

  @Get('pagos-recurrentes')
  async pagosRecurrentes(@Headers('authorization') authorization?: string) {
    this.verificar(authorization);
    return this.scheduler.ejecutarPendientes();
  }

  private verificar(authorization?: string) {
    const secret = this.config.get<string>('CRON_SECRET');
    // Sin secreto configurado la ruta queda cerrada: nadie más puede dispararla
    if (!secret || !authorization) throw new UnauthorizedException();
    const esperado = Buffer.from(`Bearer ${secret}`);
    const recibido = Buffer.from(authorization);
    if (esperado.length !== recibido.length || !timingSafeEqual(esperado, recibido)) {
      throw new UnauthorizedException();
    }
  }
}
