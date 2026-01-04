import { IsNotEmpty, IsString, IsOptional, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { IsMonedaValid } from '../../common/validators/is-moneda-valid.validator';
import { MonedasConstants } from '../../common/constants/monedas.constants';

export class UpdateProfileDto {
  @ApiProperty({ example: 'Juan Pérez', description: 'Nombre completo del usuario' })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  @IsString({ message: 'El nombre debe ser un texto' })
  nombre: string;

  @ApiProperty({ example: '+50212345678', description: 'Teléfono del usuario (opcional)', required: false })
  @IsOptional()
  @Matches(/^\+?[1-9]\d{1,14}$/, { message: 'El teléfono no es válido' })
  telefono?: string;

  @ApiProperty({ example: '1990-01-15', description: 'Fecha de nacimiento (opcional)', required: false })
  @IsOptional()
  fechaNacimiento?: Date;

  @ApiProperty({ 
    example: 'COP', 
    description: 'Moneda predeterminada (código ISO 4217). Monedas válidas: ' + MonedasConstants.getMonedasValidas().join(', '),
    default: 'COP', 
    required: false,
    enum: MonedasConstants.getMonedasValidas(),
  })
  @IsOptional()
  @IsMonedaValid({ message: 'La moneda proporcionada no es válida. Debe ser un código ISO 4217 de un país de habla hispana.' })
  monedaPredeterminada?: string;
}

