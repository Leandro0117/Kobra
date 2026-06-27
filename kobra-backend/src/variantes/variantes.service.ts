import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVarianteDto } from './dto/create-variante.dto';
import { UpdateVarianteDto } from './dto/update-variante.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class VariantesService {
  constructor(private prisma: PrismaService) {}

  async create(productoId: number, dto: CreateVarianteDto) {
    const producto = await this.prisma.producto.findUnique({ where: { id: productoId } });
    if (!producto) {
      throw new NotFoundException(`Producto ${productoId} no encontrado`);
    }
    return this.prisma.variante.create({ data: { ...dto, productoId } });
  }

  async findOne(id: number) {
    const variante = await this.prisma.variante.findUnique({ where: { id } });
    if (!variante) {
      throw new NotFoundException(`Variante ${id} no encontrada`);
    }
    return variante;
  }

  async update(id: number, dto: UpdateVarianteDto) {
    await this.findOne(id);
    return this.prisma.variante.update({ where: { id }, data: dto });
  }

  async remove(id: number) {
    await this.findOne(id);
    try {
      return await this.prisma.variante.delete({ where: { id } });
    } catch (error) {
      if (esErrorDeForeignKey(error)) {
        throw new BadRequestException(
          'No se puede eliminar la variante porque está en ventas registradas',
        );
      }
      throw error;
    }
  }
}
