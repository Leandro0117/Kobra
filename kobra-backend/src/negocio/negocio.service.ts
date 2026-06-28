import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertNegocioDto } from './dto/upsert-negocio.dto';

// Negocio es un registro único (singleton): siempre se lee/escribe con id 1.
const ID_NEGOCIO = 1;

@Injectable()
export class NegocioService {
  constructor(private prisma: PrismaService) {}

  obtener() {
    return this.prisma.negocio.findUnique({ where: { id: ID_NEGOCIO } });
  }

  guardar(dto: UpsertNegocioDto) {
    return this.prisma.negocio.upsert({
      where: { id: ID_NEGOCIO },
      update: dto,
      create: { id: ID_NEGOCIO, ...dto },
    });
  }
}
