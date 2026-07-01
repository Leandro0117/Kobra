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
import { ClientesService } from './clientes.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('clientes')
@UseGuards(RolesGuard)
export class ClientesController {
  constructor(private clientesService: ClientesService) {}

  @Post()
  create(@Body() dto: CreateClienteDto, @CurrentUser() usuario: UsuarioActual) {
    return this.clientesService.create(dto, usuario.negocioId);
  }

  @Get()
  findAll(@CurrentUser() usuario: UsuarioActual) {
    return this.clientesService.findAll(usuario.negocioId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.clientesService.findOne(id, usuario.negocioId);
  }

  @Get(':id/detalle')
  obtenerDetalle(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.clientesService.obtenerDetalle(id, usuario.negocioId);
  }

  @Patch(':id')
  @Roles(Rol.ADMIN)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateClienteDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.clientesService.update(id, dto, usuario.negocioId);
  }

  @Delete(':id')
  @Roles(Rol.ADMIN)
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.clientesService.remove(id, usuario.negocioId);
  }
}
