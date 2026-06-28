import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInsumoDto } from './dto/create-insumo.dto';
import { UpdateInsumoDto } from './dto/update-insumo.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class InsumosService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateInsumoDto) {
    return this.prisma.insumo.create({ data: dto });
  }

  findAll() {
    return this.prisma.insumo.findMany({ orderBy: { nombre: 'asc' } });
  }

  async findOne(id: number) {
    const insumo = await this.prisma.insumo.findUnique({ where: { id } });
    if (!insumo) {
      throw new NotFoundException(`Insumo ${id} no encontrado`);
    }
    return insumo;
  }

  async update(id: number, dto: UpdateInsumoDto) {
    await this.findOne(id);
    return this.prisma.insumo.update({ where: { id }, data: dto });
  }

  async remove(id: number) {
    await this.findOne(id);
    try {
      return await this.prisma.insumo.delete({ where: { id } });
    } catch (error) {
      if (esErrorDeForeignKey(error)) {
        throw new BadRequestException(
          'No se puede eliminar el insumo porque está en gastos registrados',
        );
      }
      throw error;
    }
  }
}
