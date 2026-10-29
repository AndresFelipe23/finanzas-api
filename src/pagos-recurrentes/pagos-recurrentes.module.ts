import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PagosRecurrentesService } from './pagos-recurrentes.service';
import { PagosRecurrentesController } from './pagos-recurrentes.controller';
import { PagosRecurrentesScheduler } from './pagos-recurrentes.scheduler';
import { CronController } from './cron.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [TypeOrmModule.forFeature([]), AuthModule],
  controllers: [PagosRecurrentesController, CronController],
  providers: [PagosRecurrentesService, PagosRecurrentesScheduler],
})
export class PagosRecurrentesModule {}


