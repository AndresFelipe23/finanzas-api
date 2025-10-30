import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreatePagoNfcDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  tarjetaId!: number;

  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  dispositivoNfcId!: number;

  @ApiProperty({ example: 50000 })
  @IsNotEmpty()
  @IsNumber()
  monto!: number;

  @ApiProperty({ example: '2025-10-30T14:23:45.123', required: false })
  @IsOptional()
  @IsDateString()
  fechaTransaccion?: string;

  @ApiProperty({ example: 3, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 2, required: false })
  @IsOptional()
  @IsNumber()
  categoriaId?: number;

  @ApiProperty({ example: 'Compra supermercado', required: false })
  @IsOptional()
  @IsString()
  descripcion?: string;

  @ApiProperty({ example: 'Bogotá - Colina', required: false })
  @IsOptional()
  @IsString()
  ubicacion?: string;

  @ApiProperty({ example: 4.7110, required: false })
  @IsOptional()
  @IsNumber()
  lat?: number;

  @ApiProperty({ example: -74.0721, required: false })
  @IsOptional()
  @IsNumber()
  lon?: number;
}


