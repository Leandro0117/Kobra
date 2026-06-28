import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { FinanzasService } from './finanzas.service';
import { FiltroFechasDto } from '../common/dto/filtro-fechas.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';

@Controller('finanzas')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class FinanzasController {
  constructor(private finanzasService: FinanzasService) {}

  @Get()
  obtenerResumen(@Query() filtro: FiltroFechasDto) {
    return this.finanzasService.obtenerResumen(filtro);
  }
}
