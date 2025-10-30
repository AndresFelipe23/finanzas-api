import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreatePagoPrestamoDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  prestamoId: number;

  @ApiProperty({ example: 250000 })
  @IsNotEmpty()
  @IsNumber()
  monto: number;

  @ApiProperty({ example: '2025-02-01T00:00:00', required: false })
  @IsOptional()
  @IsString()
  fechaPago?: string;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 'Pago mensual', required: false })
  @IsOptional()
  @IsString()
  notas?: string;
}


