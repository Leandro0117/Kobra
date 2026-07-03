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

  async obtenerResumen(filtro: FiltroEstadisticasDto, negocioId: number) {
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
    };

    const whereGastos: Prisma.GastoWhereInput = {
      negocioId,
      ...(rangoFecha ? { fecha: rangoFecha } : {}),
    };

    // Una sola ronda de queries: ventas (con includes para estadísticas) + gastos
    const [ventas, gastos] = await Promise.all([
      this.prisma.venta.findMany({
        where: whereVentas,
        include: {
          cliente: true,
          detalles: { include: { variante: { include: { producto: true } } } },
        },
      }),
      this.prisma.gasto.findMany({
        where: whereGastos,
        select: { total: true, categoria: true },
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
      const cliente = porCliente.get(venta.clienteId) ?? {
        clienteId: venta.clienteId,
        nombre: venta.cliente.nombre,
        cantidadVentas: 0,
        cantidadProductos: 0,
        totalComprado: 0,
      };
      cliente.cantidadVentas += 1;
      cliente.totalComprado += venta.total;

      const dia = venta.fecha.toISOString().slice(0, 10);
      const punto = porDia.get(dia) ?? { fecha: dia, totalVentas: 0, totalFacturado: 0 };
      punto.totalVentas += 1;
      punto.totalFacturado += venta.total;
      porDia.set(dia, punto);

      for (const detalle of venta.detalles) {
        cliente.cantidadProductos += detalle.cantidad;

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

      porCliente.set(venta.clienteId, cliente);
    }

    const topClientes = [...porCliente.values()]
      .sort((a, b) => b.cantidadVentas - a.cantidadVentas)
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

    return {
      finanzas: {
        totalCobrado,
        porCobrar,
        totalEgresos,
        balance: totalCobrado - totalEgresos,
        egresosPorCategoria,
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
