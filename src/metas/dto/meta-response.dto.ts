import { ApiProperty } from '@nestjs/swagger';

export class MetaResponseDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 1 })
  usuario_id: number;

  @ApiProperty({ example: 'Viaje a Europa' })
  nombre: string;

  @ApiProperty({ example: 'Ahorrar para viajar por 3 semanas', required: false })
  descripcion?: string | null;

  @ApiProperty({ example: 5000000 })
  monto_objetivo: number;

  @ApiProperty({ example: 1500000 })
  monto_actual: number;

  @ApiProperty({ example: '2025-12-31T00:00:00' })
  fecha_objetivo: Date;

  @ApiProperty({ example: 'flight', required: false })
  icono?: string | null;

  @ApiProperty({ example: '#3B82F6', required: false })
  color?: string | null;

  @ApiProperty({ example: true })
  activa: boolean;

  @ApiProperty({ example: '2024-01-15T10:30:00' })
  fecha_creacion: Date;

  @ApiProperty({ example: '2024-01-20T15:45:00' })
  fecha_actualizacion: Date;
}

