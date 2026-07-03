import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UsuarioActual } from '../common/decorators/current-user.decorator';
import { CreateMedioPagoDto } from './dto/create-medio-pago.dto';

const DEFAULTS = ['Efectivo', 'Transferencia', 'Tarjeta'];
const ORDER = [{ esDefault: 'desc' as const }, { nombre: 'asc' as const }];

@Injectable()
export class MediosPagoService {
  constructor(private prisma: PrismaService) {}

  async findAll(usuario: UsuarioActual) {
    const existing = await this.prisma.medioPago.findMany({
      where: { negocioId: usuario.negocioId },
      orderBy: ORDER,
    });

    if (existing.length === 0) {
      await this.prisma.medioPago.createMany({
        data: DEFAULTS.map((nombre) => ({
          negocioId: usuario.negocioId,
          nombre,
          esDefault: true,
          activo: true,
        })),
      });
      return this.prisma.medioPago.findMany({
        where: { negocioId: usuario.negocioId },
        orderBy: ORDER,
      });
    }

    return existing;
  }

  async create(dto: CreateMedioPagoDto, usuario: UsuarioActual) {
    return this.prisma.medioPago.create({
      data: {
        negocioId: usuario.negocioId,
        nombre: dto.nombre,
        activo: true,
        esDefault: false,
      },
    });
  }

  async toggleActivo(id: number, usuario: UsuarioActual) {
    const medio = await this.prisma.medioPago.findFirst({
      where: { id, negocioId: usuario.negocioId },
    });
    if (!medio) throw new NotFoundException(`Medio de pago ${id} no encontrado`);
    return this.prisma.medioPago.update({
      where: { id },
      data: { activo: !medio.activo },
    });
  }

  async remove(id: number, usuario: UsuarioActual) {
    const medio = await this.prisma.medioPago.findFirst({
      where: { id, negocioId: usuario.negocioId },
    });
    if (!medio) throw new NotFoundException(`Medio de pago ${id} no encontrado`);
    if (medio.esDefault) {
      throw new BadRequestException('Los medios predeterminados no se pueden eliminar, solo deshabilitar');
    }
    return this.prisma.medioPago.delete({ where: { id } });
  }
}
