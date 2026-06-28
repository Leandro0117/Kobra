import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query, UseGuards } from '@nestjs/common';
import { GastosService } from './gastos.service';
import { CreateGastoDto } from './dto/create-gasto.dto';
import { FiltroGastosDto } from './dto/filtro-gastos.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('gastos')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class GastosController {
  constructor(private gastosService: GastosService) {}

  @Post()
  create(@Body() dto: CreateGastoDto, @CurrentUser() usuario: UsuarioActual) {
    return this.gastosService.create(dto, usuario);
  }

  @Get()
  findAll(@Query() filtro: FiltroGastosDto) {
    return this.gastosService.findAll(filtro);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.gastosService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.gastosService.remove(id);
  }
}
