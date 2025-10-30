import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class RegisterDispositivoDto {
  @ApiProperty({ example: 'Mi Teléfono' })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiProperty({ example: 'TELEFONO', enum: ['TELEFONO', 'SMARTWATCH', 'TAG', 'PULSERA', 'OTRO'] })
  @IsString()
  @IsIn(['TELEFONO', 'SMARTWATCH', 'TAG', 'PULSERA', 'OTRO'])
  tipo_dispositivo: string;

  @ApiProperty({ example: 'a3f7f9d0-6b9c-4b8e-bb8a-0c1d2e3f4a5b' })
  @IsString()
  @IsNotEmpty()
  identificador_unico: string;

  @ApiProperty({ example: 'Pixel 7', required: false })
  @IsOptional()
  @IsString()
  modelo?: string;
}


