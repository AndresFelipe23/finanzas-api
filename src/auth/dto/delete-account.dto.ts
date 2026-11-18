import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

/** Confirmación para eliminar la cuenta: la contraseña actual. */
export class DeleteAccountDto {
  @ApiProperty({ example: 'MiContraseña123', description: 'Contraseña actual, para confirmar' })
  @IsNotEmpty({ message: 'Escribe tu contraseña para confirmar' })
  @IsString()
  password: string;
}
