import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { PresupuestosService } from './presupuestos.service';
import { CreatePresupuestoDto } from './dto/create-presupuesto.dto';
import { UpdatePresupuestoDto } from './dto/update-presupuesto.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@Controller('presupuestos')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PresupuestosController {
  constructor(private readonly service: PresupuestosService) {}

  @Post()
  async create(
    @Body() dto: CreatePresupuestoDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.service.create(usuarioId, dto);
  }

  @Get()
  async findAll(
    @CurrentUserId() usuarioId: number,
    @Query('activos') activos?: string,
  ) {
    const flag = activos === undefined ? undefined : activos === 'true' || activos === '1';
    return await this.service.findAll(usuarioId, flag);
  }

  @Get('resumen')
  async resumen(
    @CurrentUserId() usuarioId: number,
    @Query('fecha') fecha?: string,
  ) {
    return await this.service.resumen(usuarioId, fecha);
  }

  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.service.findOne(usuarioId, +id);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdatePresupuestoDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.service.update(usuarioId, +id, dto);
  }

  @Patch(':id/toggle')
  async toggle(
    @Param('id') id: string,
    @Query('activo') activo: string,
    @CurrentUserId() usuarioId: number,
  ) {
    const flag = activo === 'true' || activo === '1';
    return await this.service.toggle(usuarioId, +id, flag);
  }

  @Patch(':id/recalc')
  async recalc(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.service.recalc(usuarioId, +id);
  }

  @Delete(':id')
  async remove(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.service.remove(usuarioId, +id);
  }
}


