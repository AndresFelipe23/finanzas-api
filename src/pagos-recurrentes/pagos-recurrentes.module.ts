import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PagosRecurrentesService } from './pagos-recurrentes.service';
import { PagosRecurrentesController } from './pagos-recurrentes.controller';
import { PagosRecurrentesScheduler } from './pagos-recurrentes.scheduler';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [TypeOrmModule.forFeature([]), AuthModule],
  controllers: [PagosRecurrentesController],
  providers: [PagosRecurrentesService, PagosRecurrentesScheduler],
})
export class PagosRecurrentesModule {}


