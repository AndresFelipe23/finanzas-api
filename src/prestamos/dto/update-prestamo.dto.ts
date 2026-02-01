import { PartialType } from '@nestjs/swagger';
import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsBoolean } from 'class-validator';
import { CreatePrestamoDto } from './create-prestamo.dto';

export class UpdatePrestamoDto extends PartialType(CreatePrestamoDto) {
  // incluye 'activa' opcional para toggle via update si se requiere
  @ApiProperty({ example: true, required: false, description: 'Estado activo del préstamo' })
  @IsOptional()
  @IsBoolean()
  activa?: boolean;
}


