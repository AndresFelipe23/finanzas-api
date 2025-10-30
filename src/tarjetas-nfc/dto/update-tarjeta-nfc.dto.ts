import { PartialType } from '@nestjs/swagger';
import { CreateTarjetaNfcDto } from './create-tarjeta-nfc.dto';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateTarjetaNfcDto extends PartialType(CreateTarjetaNfcDto) {
  @IsOptional()
  @IsBoolean()
  activa?: boolean;
}


