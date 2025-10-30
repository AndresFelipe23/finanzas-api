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
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TransaccionesService } from './transacciones.service';
import { CreateTransaccionDto } from './dto/create-transaccion.dto';
import { UpdateTransaccionDto } from './dto/update-transaccion.dto';
import { TransaccionResponseDto } from './dto/transaccion-response.dto';

@ApiTags('Transacciones')
@Controller('transacciones')
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
  @ApiBearerAuth()
  async create(
    @Body() createTransaccionDto: CreateTransaccionDto,
  ): Promise<TransaccionResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
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
    }
  ): Promise<TransaccionResponseDto[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
  async findAll(
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string
  ): Promise<TransaccionResponseDto[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async getSummary(
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string
  ): Promise<any[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async findByAccount(
    @Param('cuentaId', ParseIntPipe) cuentaId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string
  ): Promise<TransaccionResponseDto[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async findByCategory(
    @Param('categoriaId', ParseIntPipe) categoriaId: number,
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string
  ): Promise<TransaccionResponseDto[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async findOne(
    @Param('id', ParseIntPipe) id: number
  ): Promise<TransaccionResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateTransaccionDto: UpdateTransaccionDto
  ): Promise<TransaccionResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
    return await this.transaccionesService.update(id, usuarioId, updateTransaccionDto);
  }

  @Delete(':id')
  @ApiOperation({ 
    summary: 'Eliminar transacción', 
    description: 'Elimina una transacción (soft delete)' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Transacción eliminada exitosamente' 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Transacción no encontrada' 
  })
  @ApiBearerAuth()
  async remove(
    @Param('id', ParseIntPipe) id: number
  ): Promise<{ message: string }> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    
    return await this.transaccionesService.remove(id, usuarioId);
  }
}

