import { IsNotEmpty, IsNumber, IsOptional, IsString, IsBoolean, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTransaccionDto {
  @ApiProperty({ 
    example: 1, 
    description: 'ID de la cuenta',
    required: false 
  })
  @IsOptional()
  @IsNumber({}, { message: 'El ID de cuenta debe ser un número' })
  cuentaId?: number;

  @ApiProperty({ 
    example: 1, 
    description: 'ID del tipo de transacción',
    required: true 
  })
  @IsNotEmpty({ message: 'El tipo de transacción es requerido' })
  @IsNumber({}, { message: 'El ID del tipo de transacción debe ser un número' })
  tipoTransaccionId: number;

  @ApiProperty({ 
    example: 1, 
    description: 'ID de la categoría',
    required: false 
  })
  @IsOptional()
  @IsNumber({}, { message: 'El ID de categoría debe ser un número' })
  categoriaId?: number;

  @ApiProperty({ 
    example: 1, 
    description: 'ID del método de pago',
    required: false 
  })
  @IsOptional()
  @IsNumber({}, { message: 'El ID del método de pago debe ser un número' })
  metodoPagoId?: number;

  @ApiProperty({ 
    example: 100.00, 
    description: 'Monto de la transacción' 
  })
  @IsNotEmpty({ message: 'El monto es requerido' })
  @IsNumber({}, { message: 'El monto debe ser un número' })
  @Min(0, { message: 'El monto no puede ser negativo' })
  monto: number;

  @ApiProperty({ 
    example: 'COP', 
    description: 'Moneda de la transacción',
    default: 'COP'
  })
  @IsOptional()
  @IsString({ message: 'La moneda debe ser un texto' })
  moneda?: string;

  @ApiProperty({ 
    example: 'Arriendo apartamento', 
    description: 'Título corto de la transacción',
    required: false
  })
  @IsOptional()
  @IsString({ message: 'El título debe ser un texto' })
  titulo?: string;

  @ApiProperty({ 
    example: 'Pago de servicios', 
    description: 'Descripción de la transacción', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'La descripción debe ser un texto' })
  descripcion?: string;

  @ApiProperty({ 
    example: '2025-10-29', 
    description: 'Fecha de la transacción (YYYY-MM-DD)', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'La fecha debe ser válida' })
  fechaTransaccion?: string;

  @ApiProperty({ 
    example: 'https://example.com/recibo.jpg', 
    description: 'URL del archivo adjunto',
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'El archivo adjunto debe ser un texto' })
  archivoAdjunto?: string;

  @ApiProperty({ 
    example: 'Notas adicionales', 
    description: 'Notas sobre la transacción',
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'Las notas deben ser un texto' })
  notas?: string;

  @ApiProperty({ 
    example: false, 
    description: 'Si la transacción se repite',
    required: false 
  })
  @IsOptional()
  @IsBoolean({ message: 'El campo repetir debe ser un booleano' })
  repetir?: boolean;
}

