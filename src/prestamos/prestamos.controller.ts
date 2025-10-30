import { Controller, Get, Post, Body, Patch, Param, Query, Delete } from '@nestjs/common';
import { PrestamosService } from './prestamos.service';
import { CreatePrestamoDto } from './dto/create-prestamo.dto';
import { UpdatePrestamoDto } from './dto/update-prestamo.dto';
import { CreatePagoPrestamoDto } from './dto/create-pago-prestamo.dto';
import { UpdatePagoPrestamoDto } from './dto/update-pago-prestamo.dto';

@Controller('prestamos')
export class PrestamosController {
  constructor(private readonly prestamosService: PrestamosService) {}

  // TODO: Reemplazar usuarioId hardcodeado por JWT
  private get usuarioId() {
    return 1;
  }

  @Post()
  async create(@Body() dto: CreatePrestamoDto) {
    return await this.prestamosService.create(this.usuarioId, dto);
  }

  @Get()
  async findAll(@Query('activos') activos?: string) {
    const flag = activos === undefined ? undefined : activos === 'true' || activos === '1';
    return await this.prestamosService.findAll(this.usuarioId, flag);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return await this.prestamosService.findOne(this.usuarioId, +id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdatePrestamoDto) {
    return await this.prestamosService.update(this.usuarioId, +id, dto);
  }

  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Query('activa') activa: string) {
    const value = activa === 'true' || activa === '1';
    return await this.prestamosService.toggle(this.usuarioId, +id, value);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return await this.prestamosService.remove(this.usuarioId, +id);
  }

  // PAGOS
  @Post(':id/pagos')
  async createPago(@Param('id') id: string, @Body() dto: Omit<CreatePagoPrestamoDto, 'prestamoId'>) {
    const body: CreatePagoPrestamoDto = { ...dto, prestamoId: +id } as any;
    return await this.prestamosService.createPago(this.usuarioId, body);
  }

  @Get(':id/pagos')
  async listPagos(@Param('id') id: string) {
    return await this.prestamosService.listPagos(this.usuarioId, +id);
  }

  @Patch('pagos/:pagoId')
  async updatePago(@Param('pagoId') pagoId: string, @Body() dto: UpdatePagoPrestamoDto) {
    return await this.prestamosService.updatePago(this.usuarioId, +pagoId, dto);
  }

  @Delete('pagos/:pagoId')
  async removePago(@Param('pagoId') pagoId: string) {
    return await this.prestamosService.removePago(this.usuarioId, +pagoId);
  }
}


