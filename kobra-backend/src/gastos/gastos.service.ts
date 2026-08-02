import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGastoDto } from './dto/create-gasto.dto';
import { FiltroGastosDto } from './dto/filtro-gastos.dto';
import { UsuarioActual } from '../common/decorators/current-user.decorator';

const INCLUDE_GASTO = {
  proveedor: true,
  usuario: { select: { id: true, nombre: true, email: true } },
  detalles: { include: { insumo: true } },
} as const;

@Injectable()
export class GastosService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateGastoDto, usuario: UsuarioActual) {
    // Validar insumos solo en los detalles que los usen
    const detallesConInsumo = dto.detalles.filter((d) => d.insumoId != null);
    if (detallesConInsumo.length > 0) {
      const insumoIds = detallesConInsumo.map((d) => d.insumoId!);
      const insumos = await this.prisma.insumo.findMany({
        where: { id: { in: insumoIds }, negocioId: usuario.negocioId },
      });
      if (insumos.length !== new Set(insumoIds).size) {
        throw new BadRequestException('Uno o más insumos no existen');
      }
    }

    // Validar proveedor solo si viene
    if (dto.proveedorId != null) {
      const proveedor = await this.prisma.proveedor.findUnique({
        where: { id: dto.proveedorId, negocioId: usuario.negocioId },
      });
      if (!proveedor) throw new BadRequestException('El proveedor indicado no existe');
    }

    let total = 0;
    const detallesData = dto.detalles.map((d) => {
      total += d.precioUnitario * d.cantidad;
      return {
        insumoId: d.insumoId ?? null,
        concepto: d.concepto ?? null,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario,
      };
    });

    return this.prisma.gasto.create({
      data: {
        negocioId: usuario.negocioId,
        usuarioId: usuario.userId,
        proveedorId: dto.proveedorId ?? null,
        categoria: dto.categoria,
        total,
        detalles: { create: detallesData },
      },
      include: INCLUDE_GASTO,
    });
  }

  findAll(filtro: FiltroGastosDto, usuario: UsuarioActual) {
    const where: Record<string, unknown> = { negocioId: usuario.negocioId };
    if (filtro.proveedorId) where.proveedorId = filtro.proveedorId;
    if (filtro.categoria) where.categoria = filtro.categoria;

    const fechaFiltro: { gte?: Date; lte?: Date } = {};
    if (filtro.desde) fechaFiltro.gte = new Date(filtro.desde);
    if (filtro.hasta) fechaFiltro.lte = new Date(filtro.hasta);
    if (filtro.desde || filtro.hasta) where.fecha = fechaFiltro;

    return this.prisma.gasto.findMany({
      where,
      orderBy: { fecha: 'desc' },
      include: INCLUDE_GASTO,
    });
  }

  async findOne(id: number, usuario: UsuarioActual) {
    const gasto = await this.prisma.gasto.findUnique({
      where: { id, negocioId: usuario.negocioId },
      include: INCLUDE_GASTO,
    });
    if (!gasto) throw new NotFoundException(`Gasto ${id} no encontrado`);
    return gasto;
  }

  async remove(id: number, usuario: UsuarioActual) {
    const gasto = await this.findOne(id, usuario);
    await this.prisma.$transaction([
      this.prisma.detalleGasto.deleteMany({ where: { gastoId: gasto.id } }),
      this.prisma.gasto.delete({ where: { id: gasto.id } }),
    ]);
    return { id: gasto.id };
  }
}
