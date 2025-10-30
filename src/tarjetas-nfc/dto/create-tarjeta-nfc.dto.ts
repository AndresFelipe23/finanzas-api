import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateTarjetaNfcDto {
  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  cuentaId?: number;

  @ApiProperty({ example: 'Juan Pérez' })
  @IsNotEmpty()
  @IsString()
  nombrePortador!: string;

  @ApiProperty({ example: 'hash-xxxx-1234' })
  @IsNotEmpty()
  @IsString()
  numeroTarjetaHash!: string;

  @ApiProperty({ example: 'DEBITO', enum: ['DEBITO', 'CREDITO'] })
  @IsNotEmpty()
  @IsIn(['DEBITO', 'CREDITO'])
  tipo!: 'DEBITO' | 'CREDITO';

  @ApiProperty({ example: 'BancoX', required: false })
  @IsOptional()
  @IsString()
  banco?: string;

  @ApiProperty({ example: '#3B82F6', required: false })
  @IsOptional()
  @IsString()
  color?: string;
}


