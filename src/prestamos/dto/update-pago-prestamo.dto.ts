import { PartialType } from '@nestjs/swagger';
import { CreatePagoPrestamoDto } from './create-pago-prestamo.dto';

export class UpdatePagoPrestamoDto extends PartialType(CreatePagoPrestamoDto) {}


