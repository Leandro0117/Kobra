import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Rol } from '@prisma/client';
import { ProductosService } from './productos.service';
import { CreateProductoDto } from './dto/create-producto.dto';
import { UpdateProductoDto } from './dto/update-producto.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('productos')
@UseGuards(RolesGuard)
export class ProductosController {
  constructor(private productosService: ProductosService) {}

  @Get()
  findAll(@CurrentUser() usuario: UsuarioActual) {
    return this.productosService.findAll(usuario.negocioId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.productosService.findOne(id, usuario.negocioId);
  }

  @Post()
  @Roles(Rol.ADMIN)
  create(@Body() dto: CreateProductoDto, @CurrentUser() usuario: UsuarioActual) {
    return this.productosService.create(dto, usuario.negocioId);
  }

  @Patch(':id')
  @Roles(Rol.ADMIN)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateProductoDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.productosService.update(id, dto, usuario.negocioId);
  }

  @Delete(':id')
  @Roles(Rol.ADMIN)
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.productosService.remove(id, usuario.negocioId);
  }
}
