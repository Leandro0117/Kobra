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
import { InsumosService } from './insumos.service';
import { CreateInsumoDto } from './dto/create-insumo.dto';
import { UpdateInsumoDto } from './dto/update-insumo.dto';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Rol } from '@prisma/client';

@Controller('insumos')
@UseGuards(RolesGuard)
@Roles(Rol.ADMIN)
export class InsumosController {
  constructor(private insumosService: InsumosService) {}

  @Post()
  create(@Body() dto: CreateInsumoDto) {
    return this.insumosService.create(dto);
  }

  @Get()
  findAll() {
    return this.insumosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.insumosService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateInsumoDto) {
    return this.insumosService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.insumosService.remove(id);
  }
}
