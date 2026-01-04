import { Controller, Get, Post, Body, Patch, Param, Query, Delete, UseGuards } from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { PrestamosService } from './prestamos.service';
import { CreatePrestamoDto } from './dto/create-prestamo.dto';
import { UpdatePrestamoDto } from './dto/update-prestamo.dto';
import { CreatePagoPrestamoDto } from './dto/create-pago-prestamo.dto';
import { UpdatePagoPrestamoDto } from './dto/update-pago-prestamo.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@Controller('prestamos')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PrestamosController {
  constructor(private readonly prestamosService: PrestamosService) {}

  @Post()
  async create(
    @Body() dto: CreatePrestamoDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.create(usuarioId, dto);
  }

  @Get()
  async findAll(
    @CurrentUserId() usuarioId: number,
    @Query('activos') activos?: string,
  ) {
    const flag = activos === undefined ? undefined : activos === 'true' || activos === '1';
    return await this.prestamosService.findAll(usuarioId, flag);
  }

  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.findOne(usuarioId, +id);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdatePrestamoDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.update(usuarioId, +id, dto);
  }

  @Patch(':id/toggle')
  async toggle(
    @Param('id') id: string,
    @Query('activa') activa: string,
    @CurrentUserId() usuarioId: number,
  ) {
    const value = activa === 'true' || activa === '1';
    return await this.prestamosService.toggle(usuarioId, +id, value);
  }

  @Delete(':id')
  async remove(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.remove(usuarioId, +id);
  }

  // PAGOS
  @Post(':id/pagos')
  async createPago(
    @Param('id') id: string,
    @Body() dto: Omit<CreatePagoPrestamoDto, 'prestamoId'>,
    @CurrentUserId() usuarioId: number,
  ) {
    const body: CreatePagoPrestamoDto = { ...dto, prestamoId: +id } as any;
    return await this.prestamosService.createPago(usuarioId, body);
  }

  @Get(':id/pagos')
  async listPagos(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.listPagos(usuarioId, +id);
  }

  @Patch('pagos/:pagoId')
  async updatePago(
    @Param('pagoId') pagoId: string,
    @Body() dto: UpdatePagoPrestamoDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.updatePago(usuarioId, +pagoId, dto);
  }

  @Delete('pagos/:pagoId')
  async removePago(
    @Param('pagoId') pagoId: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return await this.prestamosService.removePago(usuarioId, +pagoId);
  }
}


