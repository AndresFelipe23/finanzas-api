import { IsNotEmpty, IsString, IsOptional, IsEnum, IsNumber, IsInt, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { IsMonedaValid } from '../../common/validators/is-moneda-valid.validator';
import { MonedasConstants } from '../../common/constants/monedas.constants';

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
    description: 'Moneda de la cuenta (código ISO 4217). Monedas válidas: ' + MonedasConstants.getMonedasValidas().join(', '),
    default: 'COP',
    enum: MonedasConstants.getMonedasValidas(),
  })
  @IsOptional()
  @IsString({ message: 'La moneda debe ser un texto' })
  @IsMonedaValid({ message: 'La moneda proporcionada no es válida. Debe ser un código ISO 4217 de un país de habla hispana.' })
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

  // ── Tarjeta de crédito (las demás cuentas no los usan) ──

  @ApiProperty({ example: 5000000, description: 'Cupo de la tarjeta de crédito', required: false })
  @IsOptional()
  @IsNumber({}, { message: 'El cupo debe ser un número' })
  @Min(0, { message: 'El cupo no puede ser negativo' })
  cupo?: number | null;

  @ApiProperty({ example: 25, description: 'Día de corte (1-31)', required: false })
  @IsOptional()
  @IsInt({ message: 'El día de corte debe ser un número entero' })
  @Min(1, { message: 'El día de corte va de 1 a 31' })
  @Max(31, { message: 'El día de corte va de 1 a 31' })
  diaCorte?: number | null;

  @ApiProperty({ example: 10, description: 'Día límite de pago (1-31)', required: false })
  @IsOptional()
  @IsInt({ message: 'El día de pago debe ser un número entero' })
  @Min(1, { message: 'El día de pago va de 1 a 31' })
  @Max(31, { message: 'El día de pago va de 1 a 31' })
  diaPago?: number | null;
}

