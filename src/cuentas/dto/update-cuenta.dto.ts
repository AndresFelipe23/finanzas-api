import { PartialType } from '@nestjs/swagger';
import { CreateCuentaDto } from './create-cuenta.dto';
import { IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCuentaDto extends PartialType(CreateCuentaDto) {
  @ApiProperty({ 
    example: true, 
    description: 'Estado activo de la cuenta', 
    required: false 
  })
  @IsOptional()
  @IsBoolean({ message: 'El campo activa debe ser un booleano' })
  activa?: boolean;
}

