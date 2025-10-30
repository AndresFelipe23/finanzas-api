import { PartialType } from '@nestjs/swagger';
import { CreatePagoRecurrenteDto } from './create-pago-recurrente.dto';

export class UpdatePagoRecurrenteDto extends PartialType(CreatePagoRecurrenteDto) {}


