import { ApiProperty } from '@nestjs/swagger';

export class TransaccionResponseDto {
  @ApiProperty({ example: 1, description: 'ID de la transacción' })
  id: number;

  @ApiProperty({ example: 1, description: 'ID del usuario' })
  usuario_id: number;

  @ApiProperty({ example: 1, description: 'ID de la cuenta', nullable: true })
  cuenta_id?: number;

  @ApiProperty({ example: 'Cuenta Principal', description: 'Nombre de la cuenta', nullable: true })
  cuenta_nombre?: string;

  @ApiProperty({ example: 1, description: 'ID del tipo de transacción' })
  tipo_transaccion_id: number;

  @ApiProperty({ example: 'INGRESO', description: 'Nombre del tipo de transacción' })
  tipo_nombre: string;

  @ApiProperty({ example: 1, description: 'ID de la categoría', nullable: true })
  categoria_id?: number;

  @ApiProperty({ example: 'Alimentación', description: 'Nombre de la categoría', nullable: true })
  categoria_nombre?: string;

  @ApiProperty({ example: '#FF0000', description: 'Color de la categoría', nullable: true })
  categoria_color?: string;

  @ApiProperty({ example: 'restaurant', description: 'Icono de la categoría', nullable: true })
  categoria_icono?: string;

  @ApiProperty({ example: 1, description: 'ID del método de pago', nullable: true })
  metodo_pago_id?: number;

  @ApiProperty({ example: 'Efectivo', description: 'Nombre del método de pago', nullable: true })
  metodo_pago_nombre?: string;

  @ApiProperty({ example: 100.00, description: 'Monto de la transacción' })
  monto: number;

  @ApiProperty({ example: 'COP', description: 'Moneda' })
  moneda: string;

  @ApiProperty({ example: 'Arriendo apartamento', description: 'Título', nullable: true })
  titulo?: string;

  @ApiProperty({ example: 'Pago de servicios', description: 'Descripción', nullable: true })
  descripcion?: string;

  @ApiProperty({ description: 'Fecha de la transacción' })
  fecha_transaccion: Date;

  @ApiProperty({ example: 'https://example.com/recibo.jpg', description: 'Archivo adjunto', nullable: true })
  archivo_adjunto?: string;

  @ApiProperty({ example: 'Notas adicionales', description: 'Notas', nullable: true })
  notas?: string;

  @ApiProperty({ example: false, description: 'Si se repite' })
  repetir: boolean;

  @ApiProperty({ example: true, description: 'Estado activo' })
  activa: boolean;

  @ApiProperty({ description: 'Fecha de creación' })
  fecha_creacion: Date;
}

