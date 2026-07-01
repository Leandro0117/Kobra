import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductoDto } from './dto/create-producto.dto';
import { UpdateProductoDto } from './dto/update-producto.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class ProductosService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateProductoDto, negocioId: number) {
    return this.prisma.producto.create({ data: { ...dto, negocioId } });
  }

  findAll(negocioId: number) {
    return this.prisma.producto.findMany({
      where: { negocioId },
      orderBy: { nombre: 'asc' },
      include: { variantes: { orderBy: { nombre: 'asc' } } },
    });
  }

  async findOne(id: number, negocioId: number) {
    const producto = await this.prisma.producto.findUnique({
      where: { id, negocioId },
      include: { variantes: { orderBy: { nombre: 'asc' } } },
    });
    if (!producto) throw new NotFoundException(`Producto ${id} no encontrado`);
    return producto;
  }

  async update(id: number, dto: UpdateProductoDto, negocioId: number) {
    await this.findOne(id, negocioId);
    return this.prisma.producto.update({ where: { id }, data: dto });
  }

  async remove(id: number, negocioId: number) {
    await this.findOne(id, negocioId);
    try {
      await this.prisma.$transaction([
        this.prisma.variante.deleteMany({ where: { productoId: id } }),
        this.prisma.producto.delete({ where: { id } }),
      ]);
      return { id };
    } catch (error) {
      if (esErrorDeForeignKey(error)) {
        throw new BadRequestException(
          'No se puede eliminar el producto porque una o más de sus variantes está en ventas registradas',
        );
      }
      throw error;
    }
  }
}
