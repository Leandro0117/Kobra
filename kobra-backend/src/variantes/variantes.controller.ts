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
import { VariantesService } from './variantes.service';
import { CreateVarianteDto } from './dto/create-variante.dto';
import { UpdateVarianteDto } from './dto/update-variante.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';

// Solo ADMIN gestiona variantes (tamaños/combinaciones con sus precios).
// Para verlas, los productos ya las incluyen anidadas en GET /productos.
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
@Controller()
export class VariantesController {
  constructor(private variantesService: VariantesService) {}

  @Post('productos/:productoId/variantes')
  create(
    @Param('productoId', ParseIntPipe) productoId: number,
    @Body() dto: CreateVarianteDto,
  ) {
    return this.variantesService.create(productoId, dto);
  }

  @Patch('variantes/:id')
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateVarianteDto) {
    return this.variantesService.update(id, dto);
  }

  @Delete('variantes/:id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.variantesService.remove(id);
  }
}
