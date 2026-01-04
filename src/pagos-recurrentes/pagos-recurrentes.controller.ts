import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PagosRecurrentesService } from './pagos-recurrentes.service';
import { CreatePagoRecurrenteDto } from './dto/create-pago-recurrente.dto';
import { UpdatePagoRecurrenteDto } from './dto/update-pago-recurrente.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@ApiTags('Pagos Recurrentes')
@Controller('pagos-recurrentes')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PagosRecurrentesController {
  constructor(private readonly service: PagosRecurrentesService) {}

  @Post()
  @ApiOperation({ summary: 'Crear pago recurrente' })
  create(
    @Body() dto: CreatePagoRecurrenteDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.create(usuarioId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Listar pagos recurrentes' })
  findAll(
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.findAll(usuarioId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener pago recurrente' })
  findOne(
    @Param('id') id: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.findOne(usuarioId, parseInt(id));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar pago recurrente' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdatePagoRecurrenteDto,
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.update(usuarioId, parseInt(id), dto);
  }

  @Patch(':id/toggle')
  @ApiOperation({ summary: 'Activar/Desactivar pago recurrente' })
  toggle(
    @Param('id') id: string,
    @Query('activo') activo: string,
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.toggle(usuarioId, parseInt(id), activo === 'true');
  }

  @Post(':id/ejecutar')
  @ApiOperation({ summary: 'Ejecutar ahora (crear transacción)' })
  ejecutar(
    @Param('id') id: string,
    @Body('fecha') fecha: string | undefined,
    @CurrentUserId() usuarioId: number,
  ) {
    return this.service.executeNow(usuarioId, parseInt(id), fecha);
  }
}


