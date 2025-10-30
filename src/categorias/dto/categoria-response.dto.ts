import { ApiProperty } from '@nestjs/swagger';

export class CategoriaResponseDto {
  @ApiProperty({ example: 1, description: 'ID de la categoría' })
  id: number;

  @ApiProperty({ example: 1, description: 'ID del usuario propietario', nullable: true })
  usuario_id?: number;

  @ApiProperty({ example: 'Alimentación', description: 'Nombre de la categoría' })
  nombre: string;

  @ApiProperty({ example: 'restaurant', description: 'Icono de la categoría', nullable: true })
  icono?: string;

  @ApiProperty({ example: '#FF6B6B', description: 'Color de la categoría', nullable: true })
  color?: string;

  @ApiProperty({ example: 'GASTO', description: 'Tipo de categoría' })
  tipo: string;

  @ApiProperty({ example: true, description: 'Estado activo' })
  activo: boolean;

  @ApiProperty({ description: 'Fecha de creación' })
  fecha_creacion: Date;
}

