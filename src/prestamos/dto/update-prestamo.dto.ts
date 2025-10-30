import { PartialType } from '@nestjs/swagger';
import { CreatePrestamoDto } from './create-prestamo.dto';

export class UpdatePrestamoDto extends PartialType(CreatePrestamoDto) {
  // incluye 'activa' opcional para toggle via update si se requiere
  activa?: boolean;
}


