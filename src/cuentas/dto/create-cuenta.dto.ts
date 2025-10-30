import { IsNotEmpty, IsString, IsOptional, IsEnum, IsNumber, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCuentaDto {
  @ApiProperty({ 
    example: 'Cuenta Principal', 
    description: 'Nombre de la cuenta' 
  })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @IsString({ message: 'El nombre debe ser un texto' })
  nombre: string;

  @ApiProperty({ 
    example: 'BANCARIA', 
    description: 'Tipo de cuenta',
    enum: ['BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'],
    default: 'BANCARIA'
  })
  @IsOptional()
  @IsEnum(['BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'], {
    message: 'El tipo de cuenta no es válido'
  })
  tipo?: 'BANCARIA' | 'EFECTIVO' | 'TARJETA_CREDITO' | 'TARJETA_DEBITO' | 'DIGITAL' | 'AHORRO' | 'INVERSION';

  @ApiProperty({ 
    example: 'COP', 
    description: 'Moneda de la cuenta',
    default: 'COP'
  })
  @IsOptional()
  @IsString({ message: 'La moneda debe ser un texto' })
  moneda?: string;

  @ApiProperty({ 
    example: 1000.00, 
    description: 'Saldo inicial de la cuenta',
    default: 0
  })
  @IsOptional()
  @IsNumber({}, { message: 'El saldo inicial debe ser un número' })
  @Min(0, { message: 'El saldo inicial no puede ser negativo' })
  saldoInicial?: number;

  @ApiProperty({ 
    example: '#10B981', 
    description: 'Color de la cuenta en formato hexadecimal', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'El color debe ser un texto' })
  color?: string;

  @ApiProperty({ 
    example: 'account_balance', 
    description: 'Icono de la cuenta', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'El icono debe ser un texto' })
  icono?: string;

  @ApiProperty({ 
    example: 'Cuenta bancaria principal', 
    description: 'Descripción de la cuenta', 
    required: false 
  })
  @IsOptional()
  @IsString({ message: 'La descripción debe ser un texto' })
  descripcion?: string;
}

