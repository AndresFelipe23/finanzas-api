import { 
  Controller, 
  Get, 
  Post, 
  Body, 
  Patch, 
  Param, 
  Delete, 
  UseGuards,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CategoriasService } from './categorias.service';
import { CreateCategoriaDto } from './dto/create-categoria.dto';
import { UpdateCategoriaDto } from './dto/update-categoria.dto';
import { CategoriaResponseDto } from './dto/categoria-response.dto';

@ApiTags('Categorías')
@Controller('categorias')
export class CategoriasController {
  constructor(private readonly categoriasService: CategoriasService) {}

  @Post()
  @ApiOperation({ 
    summary: 'Crear categoría', 
    description: 'Crea una nueva categoría personalizada para el usuario autenticado' 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'Categoría creada exitosamente',
    type: CategoriaResponseDto 
  })
  @ApiResponse({ 
    status: 409, 
    description: 'Ya existe una categoría con este nombre' 
  })
  @ApiBearerAuth()
  async create(
    @Body() createCategoriaDto: CreateCategoriaDto,
    // TODO: Extraer usuarioId del JWT cuando implementemos el guard
  ): Promise<CategoriaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.create(usuarioId, createCategoriaDto);
  }

  @Get()
  @ApiOperation({ 
    summary: 'Obtener categorías', 
    description: 'Obtiene todas las categorías activas del usuario autenticado' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Lista de categorías',
    type: [CategoriaResponseDto] 
  })
  @ApiBearerAuth()
  async findAll(
    @Query('tipo') tipo?: 'INGRESO' | 'GASTO' | 'AMBOS'
  ): Promise<CategoriaResponseDto[]> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    
    if (tipo) {
      return await this.categoriasService.findByType(usuarioId, tipo);
    }
    
    return await this.categoriasService.findAllByUser(usuarioId);
  }

  @Get('summary')
  @ApiOperation({ 
    summary: 'Resumen de categorías', 
    description: 'Obtiene estadísticas de uso de categorías para el usuario' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Resumen de uso de categorías' 
  })
  @ApiBearerAuth()
  async getSummary(): Promise<any[]> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.getSummary(usuarioId);
  }

  @Post('default')
  @ApiOperation({ 
    summary: 'Crear categorías predeterminadas', 
    description: 'Crea categorías predeterminadas para el usuario si no tiene ninguna' 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'Categorías predeterminadas creadas exitosamente' 
  })
  @ApiResponse({ 
    status: 409, 
    description: 'El usuario ya tiene categorías personalizadas' 
  })
  @ApiBearerAuth()
  async createDefaults(): Promise<{ message: string }> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.insertDefaultCategories(usuarioId);
  }

  @Get(':id')
  @ApiOperation({ 
    summary: 'Obtener categoría', 
    description: 'Obtiene una categoría específica por su ID' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Categoría encontrada',
    type: CategoriaResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Categoría no encontrada' 
  })
  @ApiBearerAuth()
  async findOne(
    @Param('id', ParseIntPipe) id: number
  ): Promise<CategoriaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.findOne(id, usuarioId);
  }

  @Patch(':id')
  @ApiOperation({ 
    summary: 'Actualizar categoría', 
    description: 'Actualiza una categoría existente' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Categoría actualizada exitosamente',
    type: CategoriaResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Categoría no encontrada' 
  })
  @ApiBearerAuth()
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCategoriaDto: UpdateCategoriaDto
  ): Promise<CategoriaResponseDto> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.update(id, usuarioId, updateCategoriaDto);
  }

  @Delete(':id')
  @ApiOperation({ 
    summary: 'Eliminar categoría', 
    description: 'Elimina una categoría físicamente de la base de datos. No se puede eliminar si tiene transacciones asociadas. No se pueden eliminar categorías del sistema (usuario_id = NULL).' 
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Categoría eliminada exitosamente' 
  })
  @ApiResponse({ 
    status: 404, 
    description: 'Categoría no encontrada' 
  })
  @ApiResponse({ 
    status: 409, 
    description: 'No se puede eliminar porque tiene transacciones asociadas' 
  })
  @ApiBearerAuth()
  async remove(
    @Param('id', ParseIntPipe) id: number
  ): Promise<{ message: string }> {
    // TODO: Reemplazar 1 con el usuarioId del JWT
    const usuarioId = 1;
    return await this.categoriasService.remove(id, usuarioId);
  }
}

