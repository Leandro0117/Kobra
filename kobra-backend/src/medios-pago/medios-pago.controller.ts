import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { MediosPagoService } from './medios-pago.service';
import { CreateMedioPagoDto } from './dto/create-medio-pago.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('medios-pago')
export class MediosPagoController {
  constructor(private mediosPagoService: MediosPagoService) {}

  @Get()
  findAll(@CurrentUser() usuario: UsuarioActual) {
    return this.mediosPagoService.findAll(usuario);
  }

  @Post()
  create(@Body() dto: CreateMedioPagoDto, @CurrentUser() usuario: UsuarioActual) {
    return this.mediosPagoService.create(dto, usuario);
  }

  @Patch(':id/toggle')
  toggleActivo(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.mediosPagoService.toggleActivo(id, usuario);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.mediosPagoService.remove(id, usuario);
  }
}
