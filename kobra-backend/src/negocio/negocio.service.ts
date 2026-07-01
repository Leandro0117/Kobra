import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertNegocioDto } from './dto/upsert-negocio.dto';

@Injectable()
export class NegocioService {
  constructor(private prisma: PrismaService) {}

  obtener(negocioId: number) {
    return this.prisma.negocio.findUnique({ where: { id: negocioId } });
  }

  guardar(negocioId: number, dto: UpsertNegocioDto) {
    return this.prisma.negocio.update({ where: { id: negocioId }, data: dto });
  }
}
