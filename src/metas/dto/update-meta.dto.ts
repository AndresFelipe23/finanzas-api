import { PartialType } from '@nestjs/swagger';
import { CreateMetaDto } from './create-meta.dto';
import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsBoolean } from 'class-validator';

export class UpdateMetaDto extends PartialType(CreateMetaDto) {
  @ApiProperty({ example: true, description: 'Estado activo de la meta', required: false })
  @IsOptional()
  @IsBoolean({ message: 'El campo activa debe ser un booleano' })
  activa?: boolean;
}

