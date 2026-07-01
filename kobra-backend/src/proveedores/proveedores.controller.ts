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
import { ProveedoresService } from './proveedores.service';
import { CreateProveedorDto } from './dto/create-proveedor.dto';
import { UpdateProveedorDto } from './dto/update-proveedor.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('proveedores')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class ProveedoresController {
  constructor(private proveedoresService: ProveedoresService) {}

  @Post()
  create(@Body() dto: CreateProveedorDto, @CurrentUser() usuario: UsuarioActual) {
    return this.proveedoresService.create(dto, usuario.negocioId);
  }

  @Get()
  findAll(@CurrentUser() usuario: UsuarioActual) {
    return this.proveedoresService.findAll(usuario.negocioId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.proveedoresService.findOne(id, usuario.negocioId);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateProveedorDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.proveedoresService.update(id, dto, usuario.negocioId);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.proveedoresService.remove(id, usuario.negocioId);
  }
}
