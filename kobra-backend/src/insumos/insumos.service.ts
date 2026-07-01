import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInsumoDto } from './dto/create-insumo.dto';
import { UpdateInsumoDto } from './dto/update-insumo.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class InsumosService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateInsumoDto, negocioId: number) {
    return this.prisma.insumo.create({ data: { ...dto, negocioId } });
  }

  findAll(negocioId: number) {
    return this.prisma.insumo.findMany({ where: { negocioId }, orderBy: { nombre: 'asc' } });
  }

  async findOne(id: number, negocioId: number) {
    const insumo = await this.prisma.insumo.findUnique({ where: { id, negocioId } });
    if (!insumo) throw new NotFoundException(`Insumo ${id} no encontrado`);
    return insumo;
  }

  async update(id: number, dto: UpdateInsumoDto, negocioId: number) {
    await this.findOne(id, negocioId);
    return this.prisma.insumo.update({ where: { id }, data: dto });
  }

  async remove(id: number, negocioId: number) {
    await this.findOne(id, negocioId);
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
