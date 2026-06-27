import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductoDto } from './dto/create-producto.dto';
import { UpdateProductoDto } from './dto/update-producto.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class ProductosService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateProductoDto) {
    return this.prisma.producto.create({ data: dto });
  }

  findAll() {
    return this.prisma.producto.findMany({
      orderBy: { nombre: 'asc' },
      include: { variantes: { orderBy: { nombre: 'asc' } } },
    });
  }

  async findOne(id: number) {
    const producto = await this.prisma.producto.findUnique({
      where: { id },
      include: { variantes: { orderBy: { nombre: 'asc' } } },
    });
    if (!producto) {
      throw new NotFoundException(`Producto ${id} no encontrado`);
    }
    return producto;
  }

  async update(id: number, dto: UpdateProductoDto) {
    await this.findOne(id);
    return this.prisma.producto.update({ where: { id }, data: dto });
  }

  async remove(id: number) {
    await this.findOne(id);
    try {
      // Si el producto tiene variantes sin ventas asociadas, se eliminan junto con él.
      // Si alguna variante sí tiene ventas, la transacción falla completa (no se borra nada).
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
