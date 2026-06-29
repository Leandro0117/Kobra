import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class ClientesService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateClienteDto) {
    return this.prisma.cliente.create({ data: dto });
  }

  findAll() {
    return this.prisma.cliente.findMany({ orderBy: { nombre: 'asc' } });
  }

  async findOne(id: number) {
    const cliente = await this.prisma.cliente.findUnique({ where: { id } });
    if (!cliente) {
      throw new NotFoundException(`Cliente ${id} no encontrado`);
    }
    return cliente;
  }

  async update(id: number, dto: UpdateClienteDto) {
    await this.findOne(id);
    return this.prisma.cliente.update({ where: { id }, data: dto });
  }

  async obtenerDetalle(id: number) {
    const cliente = await this.findOne(id);

    // Las ventas CANCELADO no representan una compra real.
    const ventas = await this.prisma.venta.findMany({
      where: { clienteId: id, estado: { not: 'CANCELADO' } },
      include: { detalles: { include: { variante: { include: { producto: true } } } } },
    });

    const totalComprado = ventas.reduce((suma, v) => suma + v.total, 0);

    const porProducto = new Map<number, { nombre: string; cantidad: number }>();
    for (const venta of ventas) {
      for (const detalle of venta.detalles) {
        const productoId = detalle.variante.productoId;
        const producto = porProducto.get(productoId) ?? {
          nombre: detalle.variante.producto.nombre,
          cantidad: 0,
        };
        producto.cantidad += detalle.cantidad;
        porProducto.set(productoId, producto);
      }
    }

    const productoMasComprado = [...porProducto.values()].sort(
      (a, b) => b.cantidad - a.cantidad,
    )[0];

    return {
      cliente,
      cantidadVentas: ventas.length,
      totalComprado,
      productoMasComprado: productoMasComprado ?? null,
    };
  }

  async remove(id: number) {
    await this.findOne(id);
    try {
      return await this.prisma.cliente.delete({ where: { id } });
    } catch (error) {
      if (esErrorDeForeignKey(error)) {
        throw new BadRequestException(
          'No se puede eliminar el cliente porque tiene ventas asociadas',
        );
      }
      throw error;
    }
  }
}
