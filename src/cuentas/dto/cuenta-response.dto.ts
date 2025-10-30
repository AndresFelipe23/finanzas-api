import { ApiProperty } from '@nestjs/swagger';

export class CuentaResponseDto {
  @ApiProperty({ example: 1, description: 'ID de la cuenta' })
  id: number;

  @ApiProperty({ example: 1, description: 'ID del usuario propietario' })
  usuario_id: number;

  @ApiProperty({ example: 'Cuenta Principal', description: 'Nombre de la cuenta' })
  nombre: string;

  @ApiProperty({ example: 'BANCARIA', description: 'Tipo de cuenta' })
  tipo: string;

  @ApiProperty({ example: 'COP', description: 'Moneda de la cuenta' })
  moneda: string;

  @ApiProperty({ example: 1000.00, description: 'Saldo inicial' })
  saldo_inicial: number;

  @ApiProperty({ example: '#10B981', description: 'Color de la cuenta', nullable: true })
  color?: string;

  @ApiProperty({ example: 'account_balance', description: 'Icono de la cuenta', nullable: true })
  icono?: string;

  @ApiProperty({ example: 'Cuenta bancaria principal', description: 'Descripción de la cuenta', nullable: true })
  descripcion?: string;

  @ApiProperty({ example: true, description: 'Estado activo' })
  activa: boolean;

  @ApiProperty({ description: 'Fecha de creación' })
  fecha_creacion: Date;

  @ApiProperty({ example: 1500.00, description: 'Saldo actual calculado', required: false })
  saldo_actual?: number;
}

