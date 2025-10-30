import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PagosRecurrentesService } from './pagos-recurrentes.service';
import { PagosRecurrentesController } from './pagos-recurrentes.controller';
import { PagosRecurrentesScheduler } from './pagos-recurrentes.scheduler';

@Module({
  imports: [TypeOrmModule.forFeature([])],
  controllers: [PagosRecurrentesController],
  providers: [PagosRecurrentesService, PagosRecurrentesScheduler],
})
export class PagosRecurrentesModule {}


