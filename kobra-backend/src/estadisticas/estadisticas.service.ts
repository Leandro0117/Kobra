import { Injectable } from '@nestjs/common';
import { CategoriaGasto, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FiltroEstadisticasDto } from './dto/filtro-estadisticas.dto';

export interface ResumenCliente {
  clienteId: number;
  nombre: string;
  cantidadVentas: number;
  cantidadProductos: number;
  totalComprado: number;
}

export interface ResumenProducto {
  productoId: number;
  nombre: string;
  cantidadVendida: number;
  totalFacturado: number;
}

export interface ResumenVariante {
  varianteId: number;
  nombre: string;
  producto: string;
  cantidadVendida: number;
  totalFacturado: number;
}

export interface PuntoVentaDia {
  fecha: string;
  totalVentas: number;
  totalFacturado: number;
}

@Injectable()
export class EstadisticasService {
  constructor(private prisma: PrismaService) {}

  async obtenerResumen(filtro: FiltroEstadisticasDto, negocioId: number, vendedorId?: number) {
    const rangoFecha =
      filtro.desde || filtro.hasta
        ? {
            ...(filtro.desde ? { gte: new Date(filtro.desde) } : {}),
            ...(filtro.hasta ? { lte: new Date(filtro.hasta) } : {}),
          }
        : undefined;

    const whereVentas: Prisma.VentaWhereInput = {
      negocioId,
      estado: { not: 'CANCELADO' },
      ...(rangoFecha ? { fecha: rangoFecha } : {}),
      ...(vendedorId ? { vendedorId } : {}),
    };

    const whereGastos: Prisma.GastoWhereInput = {
      negocioId,
      ...(rangoFecha ? { fecha: rangoFecha } : {}),
    };

    // Los gastos son del negocio, no del vendedor — no se muestran al vendedor
    const [ventas, gastos] = await Promise.all([
      this.prisma.venta.findMany({
        where: whereVentas,
        include: {
          cliente: true,
          detalles: { include: { variante: { include: { producto: true } } } },
        },
      }),
      vendedorId
        ? Promise.resolve([] as { total: number; categoria: CategoriaGasto; detalles: { cantidad: number; precioUnitario: number; insumo: { nombre: string } | null }[] }[])
        : this.prisma.gasto.findMany({
            where: whereGastos,
            select: {
              total: true,
              categoria: true,
              detalles: {
                select: {
                  cantidad: true,
                  precioUnitario: true,
                  insumo: { select: { nombre: true } },
                },
              },
            },
          }),
    ]);

    // ── Estadísticas ──────────────────────────────────────────────────────────
    const totalVentas = ventas.length;
    const totalFacturado = ventas.reduce((s, v) => s + v.total, 0);

    const porCliente = new Map<number, ResumenCliente>();
    const porProducto = new Map<number, ResumenProducto>();
    const porVariante = new Map<number, ResumenVariante>();
    const porDia = new Map<string, PuntoVentaDia>();

    for (const venta of ventas) {
      if (venta.clienteId != null && venta.cliente != null) {
        const cliente = porCliente.get(venta.clienteId) ?? {
          clienteId: venta.clienteId,
          nombre: venta.cliente.nombre,
          cantidadVentas: 0,
          cantidadProductos: 0,
          totalComprado: 0,
        };
        cliente.cantidadVentas += 1;
        cliente.totalComprado += venta.total;
        for (const detalle of venta.detalles) {
          cliente.cantidadProductos += detalle.cantidad;
        }
        porCliente.set(venta.clienteId, cliente);
      }

      const dia = venta.fecha.toISOString().slice(0, 10);
      const punto = porDia.get(dia) ?? { fecha: dia, totalVentas: 0, totalFacturado: 0 };
      punto.totalVentas += 1;
      punto.totalFacturado += venta.total;
      porDia.set(dia, punto);

      for (const detalle of venta.detalles) {
        const productoId = detalle.variante.productoId;
        const producto = porProducto.get(productoId) ?? {
          productoId,
          nombre: detalle.variante.producto.nombre,
          cantidadVendida: 0,
          totalFacturado: 0,
        };
        producto.cantidadVendida += detalle.cantidad;
        producto.totalFacturado += detalle.cantidad * detalle.precioUnitario;
        porProducto.set(productoId, producto);

        const vId = detalle.varianteId;
        const variante = porVariante.get(vId) ?? {
          varianteId: vId,
          nombre: detalle.variante.nombre,
          producto: detalle.variante.producto.nombre,
          cantidadVendida: 0,
          totalFacturado: 0,
        };
        variante.cantidadVendida += detalle.cantidad;
        variante.totalFacturado += detalle.cantidad * detalle.precioUnitario;
        porVariante.set(vId, variante);
      }
    }

    const topClientes = [...porCliente.values()]
      .sort((a, b) => b.totalComprado - a.totalComprado)
      .slice(0, 5);

    const topProductos = [...porProducto.values()]
      .sort((a, b) => b.cantidadVendida - a.cantidadVendida)
      .slice(0, 5);

    const topVariantes = [...porVariante.values()]
      .sort((a, b) => b.cantidadVendida - a.cantidadVendida)
      .slice(0, 5);

    const ventasPorDia = [...porDia.values()].sort((a, b) => a.fecha.localeCompare(b.fecha));

    // ── Finanzas (derivadas de las ventas ya cargadas + gastos) ───────────────
    const totalCobrado = ventas
      .filter((v) => v.estado === 'PAGADO')
      .reduce((s, v) => s + v.total, 0);

    const porCobrar = ventas
      .filter((v) => v.estado !== 'PAGADO')
      .reduce((s, v) => s + v.total, 0);

    const totalEgresos = gastos.reduce((s, g) => s + g.total, 0);

    const porCategoria = new Map<CategoriaGasto, number>();
    for (const gasto of gastos) {
      porCategoria.set(gasto.categoria, (porCategoria.get(gasto.categoria) ?? 0) + gasto.total);
    }
    const egresosPorCategoria = [...porCategoria.entries()]
      .map(([categoria, total]) => ({ categoria, total }))
      .sort((a, b) => b.total - a.total);

    const porCategoriaInsumo = new Map<CategoriaGasto, Map<string, number>>();
    for (const gasto of gastos) {
      for (const detalle of gasto.detalles) {
        const porInsumo = porCategoriaInsumo.get(gasto.categoria) ?? new Map<string, number>();
        const nombre = detalle.insumo?.nombre ?? 'Sin nombre';
        porInsumo.set(nombre, (porInsumo.get(nombre) ?? 0) + detalle.cantidad * detalle.precioUnitario);
        porCategoriaInsumo.set(gasto.categoria, porInsumo);
      }
    }
    const egresosPorInsumo = Object.fromEntries(
      [...porCategoriaInsumo.entries()].map(([cat, insumos]) => [
        cat,
        [...insumos.entries()]
          .map(([nombre, total]) => ({ nombre, total }))
          .sort((a, b) => b.total - a.total),
      ]),
    );

    return {
      finanzas: {
        totalCobrado,
        porCobrar,
        totalEgresos,
        balance: totalCobrado - totalEgresos,
        egresosPorCategoria,
        egresosPorInsumo,
      },
      estadisticas: {
        totalVentas,
        totalFacturado,
        topClientes,
        topProductos,
        topVariantes,
        ventasPorDia,
      },
    };
  }
}
