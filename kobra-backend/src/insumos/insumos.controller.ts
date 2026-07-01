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
import { InsumosService } from './insumos.service';
import { CreateInsumoDto } from './dto/create-insumo.dto';
import { UpdateInsumoDto } from './dto/update-insumo.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('insumos')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class InsumosController {
  constructor(private insumosService: InsumosService) {}

  @Post()
  create(@Body() dto: CreateInsumoDto, @CurrentUser() usuario: UsuarioActual) {
    return this.insumosService.create(dto, usuario.negocioId);
  }

  @Get()
  findAll(@CurrentUser() usuario: UsuarioActual) {
    return this.insumosService.findAll(usuario.negocioId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.insumosService.findOne(id, usuario.negocioId);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateInsumoDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.insumosService.update(id, dto, usuario.negocioId);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.insumosService.remove(id, usuario.negocioId);
  }
}
