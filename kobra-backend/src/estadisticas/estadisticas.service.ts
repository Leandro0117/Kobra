import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
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

@Injectable()
export class EstadisticasService {
  constructor(private prisma: PrismaService) {}

  async obtenerResumen(filtro: FiltroEstadisticasDto) {
    // Las ventas CANCELADO no cuentan: no representan una venta real.
    const where: Prisma.VentaWhereInput = { estado: { not: 'CANCELADO' } };

    if (filtro.desde || filtro.hasta) {
      where.fecha = {
        ...(filtro.desde ? { gte: new Date(filtro.desde) } : {}),
        ...(filtro.hasta ? { lte: new Date(filtro.hasta) } : {}),
      };
    }

    const ventas = await this.prisma.venta.findMany({
      where,
      include: {
        cliente: true,
        detalles: { include: { variante: { include: { producto: true } } } },
      },
    });

    const totalVentas = ventas.length;
    const totalFacturado = ventas.reduce((suma, v) => suma + v.total, 0);

    const porCliente = new Map<number, ResumenCliente>();
    const porProducto = new Map<number, ResumenProducto>();

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
      }

      porCliente.set(venta.clienteId, cliente);
    }

    const topClientes = [...porCliente.values()]
      .sort((a, b) => b.cantidadVentas - a.cantidadVentas)
      .slice(0, 5);

    const topProductos = [...porProducto.values()]
      .sort((a, b) => b.cantidadVendida - a.cantidadVendida)
      .slice(0, 5);

    return { totalVentas, totalFacturado, topClientes, topProductos };
  }
}
