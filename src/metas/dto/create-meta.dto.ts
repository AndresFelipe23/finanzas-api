import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsDateString, IsOptional, Min, Max } from 'class-validator';

export class CreateMetaDto {
  @ApiProperty({ example: 'Viaje a Europa', description: 'Nombre de la meta' })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @IsString({ message: 'El nombre debe ser una cadena de texto' })
  nombre: string;

  @ApiProperty({ example: 'Ahorrar para viajar por 3 semanas', description: 'Descripción de la meta', required: false })
  @IsOptional()
  @IsString({ message: 'La descripción debe ser una cadena de texto' })
  descripcion?: string;

  @ApiProperty({ example: 5000000, description: 'Monto objetivo a alcanzar' })
  @IsNotEmpty({ message: 'El monto objetivo es requerido' })
  @IsNumber({}, { message: 'El monto objetivo debe ser un número' })
  @Min(0.01, { message: 'El monto objetivo debe ser mayor a 0' })
  montoObjetivo: number;

  @ApiProperty({ example: '2025-12-31', description: 'Fecha objetivo para alcanzar la meta' })
  @IsNotEmpty({ message: 'La fecha objetivo es requerida' })
  @IsDateString({}, { message: 'La fecha objetivo debe ser una fecha válida' })
  fechaObjetivo: string;

  @ApiProperty({ example: 'flight', description: 'Icono de la meta', required: false })
  @IsOptional()
  @IsString({ message: 'El icono debe ser una cadena de texto' })
  icono?: string;

  @ApiProperty({ example: '#3B82F6', description: 'Color de la meta en formato hexadecimal', required: false })
  @IsOptional()
  @IsString({ message: 'El color debe ser una cadena de texto' })
  color?: string;

  // ── Aporte automático: aparta un % de cada ingreso (null lo desactiva) ──

  @ApiProperty({ example: 10, description: '% de cada ingreso que se aparta para la meta', required: false, nullable: true })
  @IsOptional()
  @IsNumber({}, { message: 'El porcentaje debe ser un número' })
  @Min(0.01, { message: 'El porcentaje debe ser mayor a 0' })
  @Max(100, { message: 'El porcentaje no puede pasar de 100' })
  aporteAutoPorcentaje?: number | null;

  @ApiProperty({ example: 500000, description: 'Solo se aparta de ingresos de este valor o más', required: false, nullable: true })
  @IsOptional()
  @IsNumber({}, { message: 'El mínimo debe ser un número' })
  @Min(0, { message: 'El mínimo no puede ser negativo' })
  aporteAutoMinimo?: number | null;
}

