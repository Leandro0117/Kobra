import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { EstadisticasService } from './estadisticas.service';
import { FiltroEstadisticasDto } from './dto/filtro-estadisticas.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';

@Controller('estadisticas')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class EstadisticasController {
  constructor(private estadisticasService: EstadisticasService) {}

  @Get()
  obtenerResumen(@Query() filtro: FiltroEstadisticasDto) {
    return this.estadisticasService.obtenerResumen(filtro);
  }
}
