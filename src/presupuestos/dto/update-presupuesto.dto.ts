import { PartialType } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';
import { CreatePresupuestoDto } from './create-presupuesto.dto';

export class UpdatePresupuestoDto extends PartialType(CreatePresupuestoDto) {
  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}


