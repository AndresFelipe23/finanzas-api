import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateAporteDto {
  @ApiProperty({ example: 1, description: 'ID de la cuenta desde donde se hace el aporte', required: false })
  @IsOptional()
  @IsNumber({}, { message: 'El ID de cuenta debe ser un número' })
  cuentaId?: number;

  @ApiProperty({ example: 500000, description: 'Monto del aporte' })
  @IsNotEmpty({ message: 'El monto del aporte es requerido' })
  @IsNumber({}, { message: 'El monto del aporte debe ser un número' })
  @Min(0.01, { message: 'El monto del aporte debe ser mayor a 0' })
  montoAporte: number;

  @ApiProperty({ example: 'Aporte mensual', description: 'Notas sobre el aporte', required: false })
  @IsOptional()
  @IsString({ message: 'Las notas deben ser una cadena de texto' })
  notas?: string;
}

