import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Rol } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVentaDto } from './dto/create-venta.dto';
import { UpdateEstadoVentaDto } from './dto/update-estado-venta.dto';
import { FiltroVentasDto } from './dto/filtro-ventas.dto';
import { UsuarioActual } from '../common/decorators/current-user.decorator';

@Injectable()
export class VentasService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateVentaDto, usuario: UsuarioActual) {
    const varianteIds = dto.detalles.map((d) => d.varianteId);
    const variantes = await this.prisma.variante.findMany({
      where: { id: { in: varianteIds } },
    });

    if (variantes.length !== new Set(varianteIds).size) {
      throw new BadRequestException('Una o más variantes no existen');
    }

    const cliente = await this.prisma.cliente.findUnique({ where: { id: dto.clienteId } });
    if (!cliente) {
      throw new BadRequestException('El cliente indicado no existe');
    }

    const variantesPorId = new Map(variantes.map((v) => [v.id, v]));

    // El total y el precio unitario se calculan SIEMPRE en el backend a partir
    // del precio actual de la variante; nunca se confía en valores enviados por el cliente.
    let total = 0;
    const detallesData = dto.detalles.map((d) => {
      const variante = variantesPorId.get(d.varianteId)!;
      const subtotal = variante.precio * d.cantidad;
      total += subtotal;
      return {
        varianteId: d.varianteId,
        cantidad: d.cantidad,
        precioUnitario: variante.precio,
      };
    });

    return this.prisma.venta.create({
      data: {
        vendedorId: usuario.userId,
        clienteId: dto.clienteId,
        estado: dto.estado,
        total,
        detalles: {
          create: detallesData,
        },
      },
      include: {
        cliente: true,
        vendedor: { select: { id: true, nombre: true, email: true } },
        detalles: { include: { variante: { include: { producto: true } } } },
      },
    });
  }

  findAll(filtro: FiltroVentasDto, usuario: UsuarioActual) {
    const where: Record<string, unknown> = {};

    if (usuario.rol === Rol.VENDEDOR) {
      // Un vendedor solo puede ver sus propias ventas, sin importar lo que pida el filtro
      where.vendedorId = usuario.userId;
    } else if (filtro.vendedorId) {
      where.vendedorId = filtro.vendedorId;
    }

    if (filtro.clienteId) {
      where.clienteId = filtro.clienteId;
    }
    if (filtro.estado) {
      where.estado = filtro.estado;
    }

    return this.prisma.venta.findMany({
      where,
      orderBy: { fecha: 'desc' },
      include: {
        cliente: true,
        vendedor: { select: { id: true, nombre: true, email: true } },
        detalles: { include: { variante: { include: { producto: true } } } },
      },
    });
  }

  async findOne(id: number, usuario: UsuarioActual) {
    const venta = await this.prisma.venta.findUnique({
      where: { id },
      include: {
        cliente: true,
        vendedor: { select: { id: true, nombre: true, email: true } },
        detalles: { include: { variante: { include: { producto: true } } } },
      },
    });

    if (!venta) {
      throw new NotFoundException(`Venta ${id} no encontrada`);
    }

    if (usuario.rol === Rol.VENDEDOR && venta.vendedorId !== usuario.userId) {
      throw new ForbiddenException('No puedes ver ventas de otros vendedores');
    }

    return venta;
  }

  async actualizarEstado(id: number, dto: UpdateEstadoVentaDto, usuario: UsuarioActual) {
    const venta = await this.findOne(id, usuario);
    return this.prisma.venta.update({
      where: { id: venta.id },
      data: { estado: dto.estado },
      include: {
        cliente: true,
        vendedor: { select: { id: true, nombre: true, email: true } },
        detalles: { include: { variante: { include: { producto: true } } } },
      },
    });
  }
}
