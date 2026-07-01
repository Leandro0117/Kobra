import { Injectable } from '@nestjs/common';
import { CategoriaGasto, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FiltroFechasDto } from '../common/dto/filtro-fechas.dto';

export interface ResumenCategoriaGasto {
  categoria: CategoriaGasto;
  total: number;
}

@Injectable()
export class FinanzasService {
  constructor(private prisma: PrismaService) {}

  async obtenerResumen(filtro: FiltroFechasDto, negocioId: number) {
    const rangoFecha =
      filtro.desde || filtro.hasta
        ? {
            ...(filtro.desde ? { gte: new Date(filtro.desde) } : {}),
            ...(filtro.hasta ? { lte: new Date(filtro.hasta) } : {}),
          }
        : undefined;

    const whereVentaCobrada: Prisma.VentaWhereInput = { negocioId, estado: 'PAGADO' };
    const whereVentaPendiente: Prisma.VentaWhereInput = { negocioId, estado: { in: ['PENDIENTE', 'POR_PAGAR'] } };
    if (rangoFecha) {
      whereVentaCobrada.fecha = rangoFecha;
      whereVentaPendiente.fecha = rangoFecha;
    }

    const whereGasto: Prisma.GastoWhereInput = { negocioId };
    if (rangoFecha) whereGasto.fecha = rangoFecha;

    const [ventasCobradas, ventasPendientes, gastos] = await Promise.all([
      this.prisma.venta.findMany({ where: whereVentaCobrada, select: { total: true } }),
      this.prisma.venta.findMany({ where: whereVentaPendiente, select: { total: true } }),
      this.prisma.gasto.findMany({ where: whereGasto, select: { total: true, categoria: true } }),
    ]);

    const totalCobrado = ventasCobradas.reduce((suma, v) => suma + v.total, 0);
    const porCobrar = ventasPendientes.reduce((suma, v) => suma + v.total, 0);
    const totalEgresos = gastos.reduce((suma, g) => suma + g.total, 0);

    const porCategoria = new Map<CategoriaGasto, number>();
    for (const gasto of gastos) {
      porCategoria.set(gasto.categoria, (porCategoria.get(gasto.categoria) ?? 0) + gasto.total);
    }
    const egresosPorCategoria: ResumenCategoriaGasto[] = [...porCategoria.entries()]
      .map(([categoria, total]) => ({ categoria, total }))
      .sort((a, b) => b.total - a.total);

    return {
      totalCobrado,
      porCobrar,
      totalEgresos,
      balance: totalCobrado - totalEgresos,
      egresosPorCategoria,
    };
  }
}
