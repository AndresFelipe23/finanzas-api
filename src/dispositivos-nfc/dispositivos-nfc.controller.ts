import { Body, Controller, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DispositivosNfcService } from './dispositivos-nfc.service';
import { RegisterDispositivoDto } from './dto/register-dispositivo.dto';

@ApiTags('Dispositivos NFC')
@ApiBearerAuth()
@Controller('dispositivos-nfc')
export class DispositivosNfcController {
  constructor(private readonly service: DispositivosNfcService) {}

  private getUsuarioId(req: any): number {
    return req?.user?.id ?? 1; // temporal si aún no está guard activo
  }

  @Post('register')
  async register(@Req() req: any, @Body() dto: RegisterDispositivoDto) {
    const usuarioId = this.getUsuarioId(req);
    return this.service.registerOrGet(usuarioId, dto);
  }
}


