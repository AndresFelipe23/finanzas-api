import { PartialType } from '@nestjs/swagger';
import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';
import { CreatePresupuestoDto } from './create-presupuesto.dto';

export class UpdatePresupuestoDto extends PartialType(CreatePresupuestoDto) {
  @ApiProperty({ example: true, required: false, description: 'Estado activo del presupuesto' })
  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}


