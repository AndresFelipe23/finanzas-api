import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PagosRecurrentesService } from './pagos-recurrentes.service';
import { CreatePagoRecurrenteDto } from './dto/create-pago-recurrente.dto';
import { UpdatePagoRecurrenteDto } from './dto/update-pago-recurrente.dto';

@ApiTags('Pagos Recurrentes')
@Controller('pagos-recurrentes')
export class PagosRecurrentesController {
  constructor(private readonly service: PagosRecurrentesService) {}

  @Post()
  @ApiOperation({ summary: 'Crear pago recurrente' })
  @ApiBearerAuth()
  create(@Body() dto: CreatePagoRecurrenteDto) {
    const usuarioId = 1; // TODO JWT
    return this.service.create(usuarioId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Listar pagos recurrentes' })
  @ApiBearerAuth()
  findAll() {
    const usuarioId = 1; // TODO JWT
    return this.service.findAll(usuarioId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener pago recurrente' })
  @ApiBearerAuth()
  findOne(@Param('id') id: string) {
    const usuarioId = 1; // TODO JWT
    return this.service.findOne(usuarioId, parseInt(id));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar pago recurrente' })
  @ApiBearerAuth()
  update(@Param('id') id: string, @Body() dto: UpdatePagoRecurrenteDto) {
    const usuarioId = 1; // TODO JWT
    return this.service.update(usuarioId, parseInt(id), dto);
  }

  @Patch(':id/toggle')
  @ApiOperation({ summary: 'Activar/Desactivar pago recurrente' })
  @ApiBearerAuth()
  toggle(@Param('id') id: string, @Query('activo') activo: string) {
    const usuarioId = 1; // TODO JWT
    return this.service.toggle(usuarioId, parseInt(id), activo === 'true');
  }

  @Post(':id/ejecutar')
  @ApiOperation({ summary: 'Ejecutar ahora (crear transacción)' })
  @ApiBearerAuth()
  ejecutar(@Param('id') id: string, @Body('fecha') fecha?: string) {
    const usuarioId = 1; // TODO JWT
    return this.service.executeNow(usuarioId, parseInt(id), fecha);
  }
}


