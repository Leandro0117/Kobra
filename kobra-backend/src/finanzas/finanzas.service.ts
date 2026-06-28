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

  async obtenerResumen(filtro: FiltroFechasDto) {
    const rangoFecha =
      filtro.desde || filtro.hasta
        ? {
            ...(filtro.desde ? { gte: new Date(filtro.desde) } : {}),
            ...(filtro.hasta ? { lte: new Date(filtro.hasta) } : {}),
          }
        : undefined;

    // Ingresos: ventas no canceladas (igual criterio que Estadísticas).
    const whereVenta: Prisma.VentaWhereInput = { estado: { not: 'CANCELADO' } };
    if (rangoFecha) whereVenta.fecha = rangoFecha;

    // Egresos: todos los gastos registrados (no tienen estado/cancelación).
    const whereGasto: Prisma.GastoWhereInput = {};
    if (rangoFecha) whereGasto.fecha = rangoFecha;

    const [ventas, gastos] = await Promise.all([
      this.prisma.venta.findMany({ where: whereVenta, select: { total: true } }),
      this.prisma.gasto.findMany({ where: whereGasto, select: { total: true, categoria: true } }),
    ]);

    const totalIngresos = ventas.reduce((suma, v) => suma + v.total, 0);
    const totalEgresos = gastos.reduce((suma, g) => suma + g.total, 0);

    const porCategoria = new Map<CategoriaGasto, number>();
    for (const gasto of gastos) {
      porCategoria.set(gasto.categoria, (porCategoria.get(gasto.categoria) ?? 0) + gasto.total);
    }
    const egresosPorCategoria: ResumenCategoriaGasto[] = [...porCategoria.entries()]
      .map(([categoria, total]) => ({ categoria, total }))
      .sort((a, b) => b.total - a.total);

    return {
      totalIngresos,
      totalEgresos,
      balance: totalIngresos - totalEgresos,
      egresosPorCategoria,
    };
  }
}
