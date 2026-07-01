import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProveedorDto } from './dto/create-proveedor.dto';
import { UpdateProveedorDto } from './dto/update-proveedor.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class ProveedoresService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateProveedorDto, negocioId: number) {
    return this.prisma.proveedor.create({ data: { ...dto, negocioId } });
  }

  findAll(negocioId: number) {
    return this.prisma.proveedor.findMany({ where: { negocioId }, orderBy: { nombre: 'asc' } });
  }

  async findOne(id: number, negocioId: number) {
    const proveedor = await this.prisma.proveedor.findUnique({ where: { id, negocioId } });
    if (!proveedor) throw new NotFoundException(`Proveedor ${id} no encontrado`);
    return proveedor;
  }

  async update(id: number, dto: UpdateProveedorDto, negocioId: number) {
    await this.findOne(id, negocioId);
    return this.prisma.proveedor.update({ where: { id }, data: dto });
  }

  async remove(id: number, negocioId: number) {
    await this.findOne(id, negocioId);
    try {
      return await this.prisma.proveedor.delete({ where: { id } });
    } catch (error) {
      if (esErrorDeForeignKey(error)) {
        throw new BadRequestException(
          'No se puede eliminar el proveedor porque tiene gastos asociados',
        );
      }
      throw error;
    }
  }
}
