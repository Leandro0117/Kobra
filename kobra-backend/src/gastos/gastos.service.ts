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
    const insumoIds = dto.detalles.map((d) => d.insumoId);
    const insumos = await this.prisma.insumo.findMany({
      where: { id: { in: insumoIds } },
    });

    if (insumos.length !== new Set(insumoIds).size) {
      throw new BadRequestException('Uno o más insumos no existen');
    }

    const proveedor = await this.prisma.proveedor.findUnique({
      where: { id: dto.proveedorId },
    });
    if (!proveedor) {
      throw new BadRequestException('El proveedor indicado no existe');
    }

    // El total se calcula SIEMPRE en el backend a partir de cantidad x precioUnitario.
    // A diferencia de las ventas, el insumo no tiene un precio "oficial" en el catálogo
    // (varía de compra en compra), así que el precioUnitario es el que ingresa quien
    // registra el gasto; ya se validó arriba que los insumos referenciados existen.
    let total = 0;
    const detallesData = dto.detalles.map((d) => {
      total += d.precioUnitario * d.cantidad;
      return {
        insumoId: d.insumoId,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario,
      };
    });

    return this.prisma.gasto.create({
      data: {
        usuarioId: usuario.userId,
        proveedorId: dto.proveedorId,
        categoria: dto.categoria,
        total,
        detalles: { create: detallesData },
      },
      include: INCLUDE_GASTO,
    });
  }

  findAll(filtro: FiltroGastosDto) {
    const where: Record<string, unknown> = {};
    if (filtro.proveedorId) where.proveedorId = filtro.proveedorId;
    if (filtro.categoria) where.categoria = filtro.categoria;

    return this.prisma.gasto.findMany({
      where,
      orderBy: { fecha: 'desc' },
      include: INCLUDE_GASTO,
    });
  }

  async findOne(id: number) {
    const gasto = await this.prisma.gasto.findUnique({
      where: { id },
      include: INCLUDE_GASTO,
    });
    if (!gasto) {
      throw new NotFoundException(`Gasto ${id} no encontrado`);
    }
    return gasto;
  }

  async remove(id: number) {
    const gasto = await this.findOne(id);
    await this.prisma.$transaction([
      this.prisma.detalleGasto.deleteMany({ where: { gastoId: gasto.id } }),
      this.prisma.gasto.delete({ where: { id: gasto.id } }),
    ]);
    return { id: gasto.id };
  }
}
