import { IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCategoriaDto {
  @ApiProperty({ 
    example: 'Alimentación', 
    description: 'Nombre de la categoría' 
  })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @IsString({ message: 'El nombre debe ser un texto' })
  nombre: string;

  @ApiProperty({ 
    example: 'restaurant', 
    description: 'Icono de la categoría', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'El icono debe ser un texto' })
  icono?: string;

  @ApiProperty({ 
    example: '#FF6B6B', 
    description: 'Color de la categoría en formato hexadecimal', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'El color debe ser un texto' })
  color?: string;

  @ApiProperty({ 
    example: 'GASTO', 
    description: 'Tipo de categoría: INGRESO, GASTO o AMBOS',
    enum: ['INGRESO', 'GASTO', 'AMBOS'],
    default: 'GASTO'
  })
  @IsOptional()
  @IsEnum(['INGRESO', 'GASTO', 'AMBOS'], { 
    message: 'El tipo debe ser INGRESO, GASTO o AMBOS' 
  })
  tipo?: 'INGRESO' | 'GASTO' | 'AMBOS';
}

