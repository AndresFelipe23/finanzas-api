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
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CuentasService } from './cuentas.service';
import { CreateCuentaDto } from './dto/create-cuenta.dto';
import { UpdateCuentaDto } from './dto/update-cuenta.dto';
import { CuentaResponseDto } from './dto/cuenta-response.dto';

@ApiTags('Cuentas')
@Controller('cuentas')
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
  @ApiBearerAuth()
  async create(
    @Body() createCuentaDto: CreateCuentaDto,
    // TODO: Extraer usuarioId del JWT cuando implementemos el guard
  ): Promise<CuentaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
  async findAll(
    @Query('tipo') tipo?: string
  ): Promise<CuentaResponseDto[]> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    
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
  @ApiBearerAuth()
  async getSummary(): Promise<any[]> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
  async findOne(
    @Param('id', ParseIntPipe) id: number
  ): Promise<CuentaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCuentaDto: UpdateCuentaDto
  ): Promise<CuentaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
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
  @ApiBearerAuth()
  async remove(
    @Param('id', ParseIntPipe) id: number
  ): Promise<{ message: string }> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.cuentasService.remove(id, usuarioId);
  }
}

