import {
  Body,
  Controller,
  Delete,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Rol } from '@prisma/client';
import { VariantesService } from './variantes.service';
import { CreateVarianteDto } from './dto/create-variante.dto';
import { UpdateVarianteDto } from './dto/update-variante.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
@Controller()
export class VariantesController {
  constructor(private variantesService: VariantesService) {}

  @Post('productos/:productoId/variantes')
  create(
    @Param('productoId', ParseIntPipe) productoId: number,
    @Body() dto: CreateVarianteDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.variantesService.create(productoId, dto, usuario.negocioId);
  }

  @Patch('variantes/:id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateVarianteDto,
    @CurrentUser() usuario: UsuarioActual,
  ) {
    return this.variantesService.update(id, dto, usuario.negocioId);
  }

  @Delete('variantes/:id')
  remove(@Param('id', ParseIntPipe) id: number, @CurrentUser() usuario: UsuarioActual) {
    return this.variantesService.remove(id, usuario.negocioId);
  }
}
