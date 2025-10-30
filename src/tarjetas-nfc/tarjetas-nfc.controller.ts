import { Controller, Get, Post, Body, Patch, Param, Delete, Query, Req } from '@nestjs/common';
import { TarjetasNfcService } from './tarjetas-nfc.service';
import { CreateTarjetaNfcDto } from './dto/create-tarjeta-nfc.dto';
import { UpdateTarjetaNfcDto } from './dto/update-tarjeta-nfc.dto';
// TODO: Proteger con JwtAuthGuard cuando esté disponible en el proyecto
@Controller('tarjetas-nfc')
export class TarjetasNfcController {
  constructor(private readonly service: TarjetasNfcService) {}

  private getUsuarioId(req: any) {
    return req.user?.id ?? 1;
  }

  @Post()
  async create(@Req() req: any, @Body() dto: CreateTarjetaNfcDto) {
    return await this.service.create(this.getUsuarioId(req), dto);
  }

  @Get()
  async findAll(@Req() req: any, @Query('activas') activas?: string) {
    const flag = activas === undefined ? undefined : activas === 'true' || activas === '1';
    return await this.service.findAll(this.getUsuarioId(req), flag);
  }

  @Get(':id')
  async findOne(@Req() req: any, @Param('id') id: string) {
    return await this.service.findOne(this.getUsuarioId(req), +id);
  }

  @Patch(':id')
  async update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateTarjetaNfcDto) {
    return await this.service.update(this.getUsuarioId(req), +id, dto);
  }

  @Patch(':id/toggle')
  async toggle(@Req() req: any, @Param('id') id: string, @Query('activa') activa: string) {
    const flag = activa === 'true' || activa === '1';
    return await this.service.toggle(this.getUsuarioId(req), +id, flag);
  }

  @Delete(':id')
  async remove(@Req() req: any, @Param('id') id: string) {
    return await this.service.remove(this.getUsuarioId(req), +id);
  }
}


