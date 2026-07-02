import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { VentasService } from './ventas.service';
import { CreateVentaDto } from './dto/create-venta.dto';
import { UpdateVentaDto } from './dto/update-venta.dto';
import { UpdateEstadoVentaDto } from './dto/update-estado-venta.dto';
import { FiltroVentasDto } from './dto/filtro-ventas.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('ventas')
export class VentasController {
  constructor(private ventasService: VentasService) {}

  @Post()
  create(@Body() dto: CreateVentaDto, @CurrentUser() usuario: UsuarioActual) {
    return this.ventasService.create(dto, usuario);
  }

  @Get()
  findAll(@Query() filtro: FiltroVentasDto, @CurrentUser() usuario: UsuarioActual) {
    return this.ventasService.findAll(filtro, usuario);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.ventasService.findOne(id, usuario);
  }

  @Patch(':id')
  actualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateVentaDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.ventasService.actualizar(id, dto, usuario);
  }

  @Patch(':id/estado')
  actualizarEstado(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateEstadoVentaDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.ventasService.actualizarEstado(id, dto, usuario);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.ventasService.remove(id, usuario);
  }
}
