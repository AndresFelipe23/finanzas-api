import { Controller, Get, Post, Body, Param, Query, Req } from '@nestjs/common';
import { PagosNfcService } from './pagos-nfc.service';
import { CreatePagoNfcDto } from './dto/create-pago-nfc.dto';

@Controller('pagos-nfc')
export class PagosNfcController {
  constructor(private readonly service: PagosNfcService) {}

  private getUsuarioId(req: any) {
    return req.user?.id ?? 1;
  }

  @Post()
  async create(@Req() req: any, @Body() dto: CreatePagoNfcDto) {
    return await this.service.create(this.getUsuarioId(req), dto);
  }

  @Get()
  async findAll(@Req() req: any, @Query('tarjetaId') tarjetaId?: string) {
    const tid = tarjetaId ? parseInt(tarjetaId, 10) : undefined;
    return await this.service.findAll(this.getUsuarioId(req), tid);
  }

  @Get(':id')
  async findOne(@Req() req: any, @Param('id') id: string) {
    return await this.service.findOne(this.getUsuarioId(req), +id);
  }
}


