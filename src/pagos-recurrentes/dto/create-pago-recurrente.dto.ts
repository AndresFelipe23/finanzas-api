import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreatePagoRecurrenteDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  categoriaId: number;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  metodoPagoId?: number;

  @ApiProperty({ example: 50000 })
  @IsNotEmpty()
  @IsNumber()
  monto: number;

  @ApiProperty({ example: 'Pago de arriendo' })
  @IsNotEmpty()
  @IsString()
  descripcion: string;

  @ApiProperty({ example: 'MENSUAL', enum: ['DIARIO','SEMANAL','MENSUAL','BIMESTRAL','TRIMESTRAL','SEMESTRAL','ANUAL'] })
  @IsNotEmpty()
  @IsString()
  @IsIn(['DIARIO','SEMANAL','MENSUAL','BIMESTRAL','TRIMESTRAL','SEMESTRAL','ANUAL'])
  frecuencia: string;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  diaVencimiento?: number;

  @ApiProperty({ example: 1, required: false, description: '1=Lunes, 7=Domingo' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  diaSemana?: number;

  @ApiProperty({ example: '2025-11-01' })
  @IsNotEmpty()
  @IsString()
  fechaInicio: string; // YYYY-MM-DD

  @ApiProperty({ example: '2026-11-01', required: false })
  @IsOptional()
  @IsString()
  fechaFin?: string; // YYYY-MM-DD
}


