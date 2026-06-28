import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProveedorDto } from './dto/create-proveedor.dto';
import { UpdateProveedorDto } from './dto/update-proveedor.dto';
import { esErrorDeForeignKey } from '../common/prisma-errors';

@Injectable()
export class ProveedoresService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateProveedorDto) {
    return this.prisma.proveedor.create({ data: dto });
  }

  findAll() {
    return this.prisma.proveedor.findMany({ orderBy: { nombre: 'asc' } });
  }

  async findOne(id: number) {
    const proveedor = await this.prisma.proveedor.findUnique({ where: { id } });
    if (!proveedor) {
      throw new NotFoundException(`Proveedor ${id} no encontrado`);
    }
    return proveedor;
  }

  async update(id: number, dto: UpdateProveedorDto) {
    await this.findOne(id);
    return this.prisma.proveedor.update({ where: { id }, data: dto });
  }

  async remove(id: number) {
    await this.findOne(id);
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
