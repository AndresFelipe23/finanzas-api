import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({ description: 'Token recibido en el correo de recuperación' })
  @IsNotEmpty({ message: 'El token es requerido' })
  @IsString()
  token: string;

  @ApiProperty({ example: 'nuevaClave123', description: 'Nueva contraseña (mínimo 6 caracteres)' })
  @IsNotEmpty({ message: 'La contraseña es requerida' })
  @IsString()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password: string;
}
