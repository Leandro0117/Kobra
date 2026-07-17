import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Rol, TipoDescuento } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVentaDto } from './dto/create-venta.dto';
import { UpdateVentaDto } from './dto/update-venta.dto';
import { UpdateEstadoVentaDto } from './dto/update-estado-venta.dto';
import { FiltroVentasDto } from './dto/filtro-ventas.dto';
import { RegistrarPagoDto } from './dto/registrar-pago.dto';
import { UsuarioActual } from '../common/decorators/current-user.decorator';

const SELECT_VENTA = {
  id: true,
  negocioId: true,
  fecha: true,
  estado: true,
  total: true,
  descuento: true,
  tipoDescuento: true,
  montoPagado: true,
  cliente: {
    select: {
      id: true,
      nombre: true,
      telefono: true,
      notas: true,
      creadoEn: true,
    },
  },
  vendedor: { select: { id: true, nombre: true, email: true } },
  detalles: {
    select: {
      id: true,
      cantidad: true,
      precioUnitario: true,
      costoUnitario: true,
      variante: {
        select: {
          id: true,
          nombre: true,
          producto: { select: { id: true, nombre: true } },
        },
      },
    },
  },
  medioPago: { select: { id: true, nombre: true } },
} as const;

function calcularTotal(subtotal: number, descuento: number, tipo: TipoDescuento): number {
  const descuentoAplicado =
    tipo === TipoDescuento.PORCENTAJE ? subtotal * (descuento / 100) : descuento;
  return Math.max(0, subtotal - descuentoAplicado);
}

@Injectable()
export class VentasService {
  constructor(private prisma: PrismaService) {}

  // Crea una nueva venta con sus detalles y calcula el total
  async create(dto: CreateVentaDto, usuario: UsuarioActual) {
    const varianteIds = dto.detalles.map((d) => d.varianteId);
    const variantes = await this.prisma.variante.findMany({
      where: { id: { in: varianteIds }, producto: { negocioId: usuario.negocioId } },
    });

    if (variantes.length !== new Set(varianteIds).size) {
      throw new BadRequestException('Una o más variantes no existen');
    }

    const cliente = await this.prisma.cliente.findUnique({
      where: { id: dto.clienteId, negocioId: usuario.negocioId },
    });
    if (!cliente) throw new BadRequestException('El cliente indicado no existe');

    const variantesPorId = new Map(variantes.map((v) => [v.id, v]));

    let subtotal = 0;
    const detallesData = dto.detalles.map((d) => {
      const variante = variantesPorId.get(d.varianteId)!;
      subtotal += variante.precio * d.cantidad;
      return {
        varianteId: d.varianteId,
        cantidad: d.cantidad,
        precioUnitario: variante.precio,
        costoUnitario: variante.costo ?? null,
      };
    });

    const descuento = dto.descuento ?? 0;
    const tipoDescuento = dto.tipoDescuento ?? TipoDescuento.PORCENTAJE;
    const total = calcularTotal(subtotal, descuento, tipoDescuento);

    const esPagado = dto.estado === 'PAGADO';

    return this.prisma.venta.create({
      data: {
        negocioId: usuario.negocioId,
        vendedorId: usuario.userId,
        clienteId: dto.clienteId,
        estado: dto.estado,
        total,
        descuento,
        tipoDescuento,
        ...(dto.medioPagoId ? { medioPagoId: dto.medioPagoId } : {}),
        ...(esPagado ? { montoPagado: total } : {}),
        detalles: { create: detallesData },
      },
      select: SELECT_VENTA,
    });
  }
  
  // Obtiene todas las ventas del negocio del usuario, con filtros opcionales por vendedor, cliente y estado
  findAll(filtro: FiltroVentasDto, usuario: UsuarioActual) {
    const where: Record<string, unknown> = { negocioId: usuario.negocioId };

    if (usuario.rol === Rol.VENDEDOR) {
      where.vendedorId = usuario.userId;
    } else if (filtro.vendedorId) {
      where.vendedorId = filtro.vendedorId;
    }

    if (filtro.clienteId) where.clienteId = filtro.clienteId;
    if (filtro.estado) where.estado = filtro.estado;

    return this.prisma.venta.findMany({
      where,
      orderBy: { fecha: 'desc' },
      select: SELECT_VENTA,
    });
  }

  async findOne(id: number, usuario: UsuarioActual) {
    const venta = await this.prisma.venta.findUnique({
      where: { id, negocioId: usuario.negocioId },
      select: SELECT_VENTA,
    });

    if (!venta) throw new NotFoundException(`Venta ${id} no encontrada`);

    if (usuario.rol === Rol.VENDEDOR && venta.vendedor.id !== usuario.userId) {
      throw new ForbiddenException('No puedes ver ventas de otros vendedores');
    }

    return venta;
  }

  // Actualiza una venta existente, incluyendo sus detalles y recalculando el total
  async actualizar(id: number, dto: UpdateVentaDto, usuario: UsuarioActual) {
    const venta = await this.findOne(id, usuario);

    const varianteIds = dto.detalles.map((d) => d.varianteId);
    const variantes = await this.prisma.variante.findMany({
      where: { id: { in: varianteIds }, producto: { negocioId: usuario.negocioId } },
    });

    if (variantes.length !== new Set(varianteIds).size) {
      throw new BadRequestException('Una o más variantes no existen');
    }

    if (dto.clienteId !== undefined) {
      const cliente = await this.prisma.cliente.findUnique({
        where: { id: dto.clienteId, negocioId: usuario.negocioId },
      });
      if (!cliente) throw new BadRequestException('El cliente indicado no existe');
    }

    const variantesPorId = new Map(variantes.map((v) => [v.id, v]));
    let subtotal = 0;
    const detallesData = dto.detalles.map((d) => {
      const variante = variantesPorId.get(d.varianteId)!;
      subtotal += variante.precio * d.cantidad;
      return {
        varianteId: d.varianteId,
        cantidad: d.cantidad,
        precioUnitario: variante.precio,
        costoUnitario: variante.costo ?? null,
      };
    });

    const descuento = dto.descuento ?? venta.descuento;
    const tipoDescuento = dto.tipoDescuento ?? venta.tipoDescuento;
    const total = calcularTotal(subtotal, descuento, tipoDescuento);

    return this.prisma.$transaction(async (tx) => {
      await tx.detalleVenta.deleteMany({ where: { ventaId: venta.id } });
      return tx.venta.update({
        where: { id: venta.id },
        data: {
          total,
          descuento,
          tipoDescuento,
          ...(dto.clienteId !== undefined && { clienteId: dto.clienteId }),
          ...(dto.medioPagoId !== undefined && { medioPagoId: dto.medioPagoId }),
          detalles: { create: detallesData },
        },
        select: SELECT_VENTA,
      });
    });
  }

  // Actualiza el estado de una venta existente
  async actualizarEstado(id: number, dto: UpdateEstadoVentaDto, usuario: UsuarioActual) {
    const venta = await this.findOne(id, usuario);
    return this.prisma.venta.update({
      where: { id: venta.id },
      data: { estado: dto.estado },
      select: SELECT_VENTA,
    });
  }

  // Registra un pago para una venta existente y actualiza el monto pagado y el estado si corresponde
  async registrarPago(id: number, dto: RegistrarPagoDto, usuario: UsuarioActual) {
    const venta = await this.findOne(id, usuario);
    const montoPagado = venta.montoPagado + dto.monto;
    const pagoCompleto = montoPagado >= venta.total;
    return this.prisma.venta.update({
      where: { id: venta.id },
      data: {
        montoPagado,
        medioPagoId: dto.medioPagoId,
        ...(pagoCompleto && venta.estado === 'POR_PAGAR' && { estado: 'PAGADO' }),
      },
      select: SELECT_VENTA,
    });
  }

  // Elimina una venta existente y sus detalles asociados
  async remove(id: number, usuario: UsuarioActual) {
    const venta = await this.findOne(id, usuario);
    await this.prisma.$transaction([
      this.prisma.detalleVenta.deleteMany({ where: { ventaId: venta.id } }),
      this.prisma.venta.delete({ where: { id: venta.id } }),
    ]);
    return { id: venta.id };
  }
}
