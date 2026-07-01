import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { Rol } from '@prisma/client';
import { NegocioService } from './negocio.service';
import { UpsertNegocioDto } from './dto/upsert-negocio.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('negocio')
export class NegocioController {
  constructor(private negocioService: NegocioService) {}

  @Get()
  obtener(@CurrentUser() usuario: UsuarioActual) {
    return this.negocioService.obtener(usuario.negocioId);
  }

  @Patch()
  @UseGuards(RolesGuard)
  @Roles(Rol.ADMIN)
  guardar(@Body() dto: UpsertNegocioDto, @CurrentUser() usuario: UsuarioActual) {
    return this.negocioService.guardar(usuario.negocioId, dto);
  }
}
