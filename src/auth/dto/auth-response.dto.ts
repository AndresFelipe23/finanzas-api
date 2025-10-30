import { ApiProperty } from '@nestjs/swagger';

export class AuthResponseDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  accessToken: string;

  @ApiProperty({ 
    example: {
      id: 1,
      nombre: 'Juan Pérez',
      email: 'usuario@example.com'
    }
  })
  user: {
    id: number;
    nombre: string;
    email: string;
    telefono?: string;
    monedaPredeterminada?: string;
  };
}

