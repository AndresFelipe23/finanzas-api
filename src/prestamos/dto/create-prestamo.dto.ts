import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, IsIn, IsInt, Min, Max } from 'class-validator';

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

  @ApiProperty({
    example: true,
    required: false,
    description:
      'Si es true y hay cuentaId, genera el movimiento real: ingreso para DEUDA (recibes el dinero) o gasto para PRESTAMO (lo entregas). Usar false al registrar un préstamo antiguo.',
  })
  @IsOptional()
  @IsBoolean()
  registrarMovimiento?: boolean;

  // ── Crédito en cuotas (opcional). Con cuotas, montoTotal es lo que falta
  // pagar con intereses (valorCuota × cuotas restantes). null borra el dato.

  @ApiProperty({ example: 10000000, required: false, description: 'Capital prestado' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  montoPrestado?: number | null;

  @ApiProperty({ example: 'EA', enum: ['EA', 'MV'], required: false, description: 'EA: efectiva anual; MV: mes vencido' })
  @IsOptional()
  @IsIn(['EA', 'MV'], { message: 'Tipo de tasa inválido' })
  tipoTasa?: 'EA' | 'MV' | null;

  @ApiProperty({ example: 24, required: false })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(600)
  numeroCuotas?: number | null;

  @ApiProperty({ example: 520000, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  valorCuota?: number | null;

  @ApiProperty({ example: 10, required: false, description: 'Día del mes en que vence cada cuota' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  diaPago?: number | null;

  @ApiProperty({ example: '2026-11-10', required: false, description: 'Vencimiento de la cuota 1' })
  @IsOptional()
  @IsString()
  fechaPrimeraCuota?: string | null;

  @ApiProperty({ example: 6, required: false, description: 'Cuotas pagadas antes de registrarlo en la app' })
  @IsOptional()
  @IsInt()
  @Min(0)
  cuotasPrevias?: number | null;
}


