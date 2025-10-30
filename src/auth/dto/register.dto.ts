import { IsEmail, IsNotEmpty, MinLength, IsOptional, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'Juan Pérez', description: 'Nombre completo del usuario' })
  @IsNotEmpty({ message: 'El nombre es requerido' })
  nombre: string;

  @ApiProperty({ example: 'usuario@example.com', description: 'Email del usuario' })
  @IsEmail({}, { message: 'El email no es válido' })
  @IsNotEmpty({ message: 'El email es requerido' })
  email: string;

  @ApiProperty({ example: 'password123', description: 'Contraseña del usuario', minLength: 6 })
  @IsNotEmpty({ message: 'La contraseña es requerida' })
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password: string;

  @ApiProperty({ example: '+50212345678', description: 'Teléfono del usuario (opcional)', required: false })
  @IsOptional()
  @Matches(/^\+?[1-9]\d{1,14}$/, { message: 'El teléfono no es válido' })
  telefono?: string;

  @ApiProperty({ example: '1990-01-15', description: 'Fecha de nacimiento (opcional)', required: false })
  @IsOptional()
  fechaNacimiento?: Date;

  @ApiProperty({ example: 'COP', description: 'Moneda predeterminada', default: 'COP', required: false })
  @IsOptional()
  monedaPredeterminada?: string;
}

