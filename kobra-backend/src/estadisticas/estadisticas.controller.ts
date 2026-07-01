import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Rol } from '@prisma/client';
import { EstadisticasService } from './estadisticas.service';
import { FiltroEstadisticasDto } from './dto/filtro-estadisticas.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('estadisticas')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class EstadisticasController {
  constructor(private estadisticasService: EstadisticasService) {}

  @Get()
  obtenerResumen(@Query() filtro: FiltroEstadisticasDto, @CurrentUser() usuario: UsuarioActual) {
    return this.estadisticasService.obtenerResumen(filtro, usuario.negocioId);
  }
}
