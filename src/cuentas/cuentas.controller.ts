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
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CuentasService } from './cuentas.service';
import { CreateCuentaDto } from './dto/create-cuenta.dto';
import { UpdateCuentaDto } from './dto/update-cuenta.dto';
import { CuentaResponseDto } from './dto/cuenta-response.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@ApiTags('Cuentas')
@Controller('cuentas')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CuentasController {
  constructor(private readonly cuentasService: CuentasService) {}

  @Post()
  @ApiOperation({ 
    summary: 'Crear cuenta', 
    description: 'Crea una nueva cuenta para el usuario autenticado' 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'Cuenta creada exitosamente',
    type: CuentaResponseDto 
  })
  @ApiResponse({ 
    status: 409, 
    description: 'Ya existe una cuenta con este nombre' 
  })
  async create(
    @Body() createCuentaDto: CreateCuentaDto,
    @CurrentUserId() usuarioId: number,
  ): Promise<CuentaResponseDto> {
    return await this.cuentasService.create(usuarioId, createCuentaDto);
  }

  @Get()
  @ApiOperation({ 
    summary: 'Obtener cuentas', 
    description: 'Obtiene todas las cuentas activas del usuario autenticado con su saldo actual' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Lista de cuentas con saldo actual',
    type: [CuentaResponseDto] 
  })
  async findAll(
    @CurrentUserId() usuarioId: number,
    @Query('tipo') tipo?: string,
  ): Promise<CuentaResponseDto[]> {
    if (tipo) {
      return await this.cuentasService.findByType(usuarioId, tipo);
    }
    
    return await this.cuentasService.findAllByUser(usuarioId);
  }

  @Get('summary')
  @ApiOperation({ 
    summary: 'Resumen de cuentas', 
    description: 'Obtiene estadísticas de uso de cuentas para el usuario' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Resumen de uso de cuentas' 
  })
  async getSummary(
    @CurrentUserId() usuarioId: number,
  ): Promise<any[]> {
    return await this.cuentasService.getSummary(usuarioId);
  }

  @Get(':id')
  @ApiOperation({ 
    summary: 'Obtener cuenta', 
    description: 'Obtiene una cuenta específica por su ID con su saldo actual' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Cuenta encontrada',
    type: CuentaResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Cuenta no encontrada' 
  })
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUserId() usuarioId: number,
  ): Promise<CuentaResponseDto> {
    return await this.cuentasService.findOne(id, usuarioId);
  }

  @Patch(':id')
  @ApiOperation({ 
    summary: 'Actualizar cuenta', 
    description: 'Actualiza una cuenta existente' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Cuenta actualizada exitosamente',
    type: CuentaResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Cuenta no encontrada' 
  })
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCuentaDto: UpdateCuentaDto,
    @CurrentUserId() usuarioId: number,
  ): Promise<CuentaResponseDto> {
    return await this.cuentasService.update(id, usuarioId, updateCuentaDto);
  }

  @Delete(':id')
  @ApiOperation({ 
    summary: 'Eliminar cuenta', 
    description: 'Elimina una cuenta físicamente. No se puede eliminar si tiene transacciones asociadas o saldo diferente de cero' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Cuenta eliminada exitosamente' 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Cuenta no encontrada' 
  })
  @ApiResponse({ 
    status: 409, 
    description: 'No se puede eliminar porque tiene transacciones o saldo' 
  })
  async remove(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUserId() usuarioId: number,
  ): Promise<{ message: string }> {
    return await this.cuentasService.remove(id, usuarioId);
  }
}

