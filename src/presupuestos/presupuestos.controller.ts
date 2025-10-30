import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import { PresupuestosService } from './presupuestos.service';
import { CreatePresupuestoDto } from './dto/create-presupuesto.dto';
import { UpdatePresupuestoDto } from './dto/update-presupuesto.dto';

@Controller('presupuestos')
export class PresupuestosController {
  constructor(private readonly service: PresupuestosService) {}

  // TODO: Reemplazar por usuario del JWT
  private get usuarioId() {
    return 1;
  }

  @Post()
  async create(@Body() dto: CreatePresupuestoDto) {
    return await this.service.create(this.usuarioId, dto);
  }

  @Get()
  async findAll(@Query('activos') activos?: string) {
    const flag = activos === undefined ? undefined : activos === 'true' || activos === '1';
    return await this.service.findAll(this.usuarioId, flag);
  }

  @Get('resumen')
  async resumen(@Query('fecha') fecha?: string) {
    return await this.service.resumen(this.usuarioId, fecha);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return await this.service.findOne(this.usuarioId, +id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdatePresupuestoDto) {
    return await this.service.update(this.usuarioId, +id, dto);
  }

  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Query('activo') activo: string) {
    const flag = activo === 'true' || activo === '1';
    return await this.service.toggle(this.usuarioId, +id, flag);
  }

  @Patch(':id/recalc')
  async recalc(@Param('id') id: string) {
    return await this.service.recalc(this.usuarioId, +id);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return await this.service.remove(this.usuarioId, +id);
  }
}


