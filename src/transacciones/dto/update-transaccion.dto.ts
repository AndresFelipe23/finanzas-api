import { PartialType } from '@nestjs/swagger';
import { CreateTransaccionDto } from './create-transaccion.dto';
import { IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateTransaccionDto extends PartialType(CreateTransaccionDto) {
  @ApiProperty({ 
    example: true, 
    description: 'Estado activo de la transacción', 
    required: false 
  })
  @IsOptional()
  @IsBoolean({ message: 'El campo activa debe ser un booleano' })
  activa?: boolean;
}

