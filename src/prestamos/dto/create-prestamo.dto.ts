import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, IsIn } from 'class-validator';

export class CreatePrestamoDto {
  @ApiProperty({ example: 'Préstamo carro', description: 'Nombre del préstamo' })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @IsString()
  nombre: string;

  @ApiProperty({ example: 'DEUDA', enum: ['PRESTAMO', 'DEUDA'] })
  @IsNotEmpty()
  @IsIn(['PRESTAMO', 'DEUDA'], { message: 'Tipo inválido' })
  tipo: 'PRESTAMO' | 'DEUDA';

  @ApiProperty({ example: 5000000 })
  @IsNotEmpty()
  @IsNumber()
  montoTotal: number;

  @ApiProperty({ example: 12.5, required: false })
  @IsOptional()
  @IsNumber()
  tasaInteres?: number;

  @ApiProperty({ example: '2025-01-10T00:00:00', required: false })
  @IsOptional()
  @IsString()
  fechaInicio?: string;

  @ApiProperty({ example: '2026-01-10T00:00:00', required: false })
  @IsOptional()
  @IsString()
  fechaFin?: string;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 'Notas del préstamo', required: false })
  @IsOptional()
  @IsString()
  notas?: string;
}


