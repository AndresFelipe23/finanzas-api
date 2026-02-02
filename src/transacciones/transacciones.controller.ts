import { 
  Controller, 
  Get, 
  Post, 
  Body, 
  Patch, 
  Param, 
  Delete, 
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TransaccionesService } from './transacciones.service';
import { CreateTransaccionDto } from './dto/create-transaccion.dto';
import { UpdateTransaccionDto } from './dto/update-transaccion.dto';
import { TransaccionResponseDto } from './dto/transaccion-response.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@ApiTags('Transacciones')
@Controller('transacciones')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class TransaccionesController {
  constructor(private readonly transaccionesService: TransaccionesService) {}

  @Post()
  @ApiOperation({ 
    summary: 'Crear transacción', 
    description: 'Crea una nueva transacción para el usuario autenticado' 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'Transacción creada exitosamente',
    type: TransaccionResponseDto 
  })
  async create(
    @Body() createTransaccionDto: CreateTransaccionDto,
    @CurrentUserId() usuarioId: number,
  ): Promise<TransaccionResponseDto> {
    return await this.transaccionesService.create(usuarioId, createTransaccionDto);
  }

  @Post('transfer')
  @ApiOperation({
    summary: 'Crear transferencia',
    description: 'Crea una transferencia entre dos cuentas del usuario'
  })
  @ApiResponse({
    status: 201,
    description: 'Transferencia creada exitosamente',
    type: [TransaccionResponseDto]
  })
  async createTransfer(
    @Body() body: {
      cuentaOrigenId: number;
      cuentaDestinoId: number;
      monto: number;
      moneda?: string;
      titulo?: string;
      descripcion?: string;
      fechaTransaccion?: string;
      notas?: string;
    },
    @CurrentUserId() usuarioId: number,
  ): Promise<TransaccionResponseDto[]> {
    return await this.transaccionesService.createTransfer(
      usuarioId,
      body.cuentaOrigenId,
      body.cuentaDestinoId,
      body.monto,
      body.moneda,
      body.titulo,
      body.descripcion,
      body.fechaTransaccion,
      body.notas
    );
  }

  @Get()
  @ApiOperation({ 
    summary: 'Obtener transacciones', 
    description: 'Obtiene todas las transacciones del usuario con filtros opcionales' 
  })
  @ApiQuery({ name: 'fechaInicio', required: false, type: String })
  @ApiQuery({ name: 'fechaFin', required: false, type: String })
  @ApiResponse({ 
    status: 200, 
    description: 'Lista de transacciones',
    type: [TransaccionResponseDto] 
  })
  async findAll(
    @CurrentUserId() usuarioId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string,
  ): Promise<TransaccionResponseDto[]> {
    return await this.transaccionesService.findAllByUser(
      usuarioId,
      fechaInicio ? new Date(fechaInicio) : undefined,
      fechaFin ? new Date(fechaFin) : undefined
    );
  }

  @Get('summary')
  @ApiOperation({ 
    summary: 'Resumen de transacciones', 
    description: 'Obtiene estadísticas de transacciones del usuario' 
  })
  @ApiQuery({ name: 'fechaInicio', required: false, type: String })
  @ApiQuery({ name: 'fechaFin', required: false, type: String })
  @ApiResponse({ 
    status: 200, 
    description: 'Resumen de transacciones' 
  })
  async getSummary(
    @CurrentUserId() usuarioId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string,
  ): Promise<any[]> {
    return await this.transaccionesService.getSummary(
      usuarioId,
      fechaInicio ? new Date(fechaInicio) : undefined,
      fechaFin ? new Date(fechaFin) : undefined
    );
  }

  @Get('cuenta/:cuentaId')
  @ApiOperation({ 
    summary: 'Transacciones por cuenta', 
    description: 'Obtiene todas las transacciones de una cuenta específica' 
  })
  @ApiQuery({ name: 'fechaInicio', required: false, type: String })
  @ApiQuery({ name: 'fechaFin', required: false, type: String })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacciones de la cuenta',
    type: [TransaccionResponseDto] 
  })
  async findByAccount(
    @CurrentUserId() usuarioId: number,
    @Param('cuentaId', ParseIntPipe) cuentaId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string,
  ): Promise<TransaccionResponseDto[]> {
    return await this.transaccionesService.findByAccount(
      usuarioId,
      cuentaId,
      fechaInicio ? new Date(fechaInicio) : undefined,
      fechaFin ? new Date(fechaFin) : undefined
    );
  }

  @Get('categoria/:categoriaId')
  @ApiOperation({ 
    summary: 'Transacciones por categoría', 
    description: 'Obtiene todas las transacciones de una categoría específica' 
  })
  @ApiQuery({ name: 'fechaInicio', required: false, type: String })
  @ApiQuery({ name: 'fechaFin', required: false, type: String })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacciones de la categoría',
    type: [TransaccionResponseDto] 
  })
  async findByCategory(
    @CurrentUserId() usuarioId: number,
    @Param('categoriaId', ParseIntPipe) categoriaId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string,
  ): Promise<TransaccionResponseDto[]> {
    return await this.transaccionesService.findByCategory(
      usuarioId,
      categoriaId,
      fechaInicio ? new Date(fechaInicio) : undefined,
      fechaFin ? new Date(fechaFin) : undefined
    );
  }

  @Get(':id')
  @ApiOperation({ 
    summary: 'Obtener transacción', 
    description: 'Obtiene una transacción específica por su ID' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacción encontrada',
    type: TransaccionResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Transacción no encontrada' 
  })
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUserId() usuarioId: number,
  ): Promise<TransaccionResponseDto> {
    return await this.transaccionesService.findOne(id, usuarioId);
  }

  @Patch(':id')
  @ApiOperation({ 
    summary: 'Actualizar transacción', 
    description: 'Actualiza una transacción existente' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacción actualizada exitosamente',
    type: TransaccionResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Transacción no encontrada' 
  })
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateTransaccionDto: UpdateTransaccionDto,
    @CurrentUserId() usuarioId: number,
  ): Promise<TransaccionResponseDto> {
    return await this.transaccionesService.update(id, usuarioId, updateTransaccionDto);
  }

  @Delete(':id')
  @ApiOperation({ 
    summary: 'Eliminar transacción', 
    description: 'Elimina una transacción (soft delete)' 
  })
  @ApiQuery({ name: 'permanent', required: false, type: Boolean, description: 'Si es true, elimina permanentemente' })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacción eliminada exitosamente' 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Transacción no encontrada' 
  })
  async remove(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUserId() usuarioId: number,
    @Query('permanent') permanent?: string,
  ): Promise<{ message: string }> {
    const isPermanent = permanent === 'true' || permanent === '1';
    
    if (isPermanent) {
      return await this.transaccionesService.removePermanently(id, usuarioId);
    } else {
      return await this.transaccionesService.remove(id, usuarioId);
    }
  }
}

