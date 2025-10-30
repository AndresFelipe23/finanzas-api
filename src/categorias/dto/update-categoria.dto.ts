import { PartialType } from '@nestjs/swagger';
import { CreateCategoriaDto } from './create-categoria.dto';
import { IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCategoriaDto extends PartialType(CreateCategoriaDto) {
  @ApiProperty({ 
    example: true, 
    description: 'Estado activo de la categoría', 
    required: false 
  })
  @IsOptional()
  @IsBoolean({ message: 'El campo activo debe ser un booleano' })
  activo?: boolean;
}

