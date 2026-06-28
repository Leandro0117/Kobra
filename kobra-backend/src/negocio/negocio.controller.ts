import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { NegocioService } from './negocio.service';
import { UpsertNegocioDto } from './dto/upsert-negocio.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';

@Controller('negocio')
export class NegocioController {
  constructor(private negocioService: NegocioService) {}

  // Cualquier usuario autenticado puede ver la info del negocio.
  @Get()
  obtener() {
    return this.negocioService.obtener();
  }

  // Solo ADMIN puede crear/editar la info del negocio.
  @Patch()
  @UseGuards(RolesGuard)
  @Roles(Rol.ADMIN)
  guardar(@Body() dto: UpsertNegocioDto) {
    return this.negocioService.guardar(dto);
  }
}
