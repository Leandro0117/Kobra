import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Rol } from '@prisma/client';
import { FinanzasService } from './finanzas.service';
import { FiltroFechasDto } from '../common/dto/filtro-fechas.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('finanzas')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class FinanzasController {
  constructor(private finanzasService: FinanzasService) {}

  @Get()
  obtenerResumen(@Query() filtro: FiltroFechasDto, @CurrentUser() usuario: UsuarioActual) {
    return this.finanzasService.obtenerResumen(filtro, usuario.negocioId);
  }
}
