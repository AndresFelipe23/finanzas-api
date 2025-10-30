import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsNumber, IsOptional, IsString, IsDateString } from 'class-validator';

export class CreatePresupuestoDto {
  @ApiProperty({ example: 'Gastos de comida' })
  @IsNotEmpty()
  @IsString()
  nombre: string;

  @ApiProperty({ example: 'MENSUAL', enum: ['SEMANAL', 'MENSUAL', 'ANUAL', 'PERSONALIZADO'] })
  @IsNotEmpty()
  @IsIn(['SEMANAL', 'MENSUAL', 'ANUAL', 'PERSONALIZADO'])
  periodo: string;

  @ApiProperty({ example: '2025-11-01T00:00:00', required: false })
  @IsOptional()
  @IsDateString()
  fechaInicio?: string;

  @ApiProperty({ example: '2025-11-30T23:59:59', required: false })
  @IsOptional()
  @IsDateString()
  fechaFin?: string;

  @ApiProperty({ example: 800000 })
  @IsNotEmpty()
  @IsNumber()
  montoLimite: number;

  @ApiProperty({ example: 3, required: false })
  @IsOptional()
  @IsNumber()
  categoriaId?: number;

  @ApiProperty({ example: 2, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 'Solo aplica para restaurantes', required: false })
  @IsOptional()
  @IsString()
  notas?: string;
}


