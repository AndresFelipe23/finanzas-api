import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({ description: 'Token de refresco emitido al iniciar sesión' })
  @IsNotEmpty({ message: 'El token de refresco es requerido' })
  @IsString()
  refreshToken: string;
}
