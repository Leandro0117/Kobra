import { ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { UsuarioActual } from '../common/decorators/current-user.decorator';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { CrearVendedorDto } from './dto/crear-vendedor.dto';
import { ActualizarVendedorDto } from './dto/actualizar-vendedor.dto';
import { CambiarPasswordDto } from './dto/cambiar-password.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async login(dto: LoginDto) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { email: dto.email },
    });

    if (!usuario) throw new UnauthorizedException('Credenciales inválidas');

    const passwordValida = await bcrypt.compare(dto.password, usuario.password);
    if (!passwordValida) throw new UnauthorizedException('Credenciales inválidas');

    const payload = { sub: usuario.id, email: usuario.email, rol: usuario.rol, negocioId: usuario.negocioId };
    const accessToken = await this.jwtService.signAsync(payload);

    return {
      accessToken,
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        email: usuario.email,
        rol: usuario.rol,
        negocioId: usuario.negocioId,
      },
    };
  }

  async register(dto: RegisterDto) {
    const existente = await this.prisma.usuario.findUnique({ where: { email: dto.email } });
    if (existente) throw new ConflictException('Ya existe un usuario con ese email');

    const hash = await bcrypt.hash(dto.password, 10);

    const usuario = await this.prisma.$transaction(async (tx) => {
      const negocio = await tx.negocio.create({ data: dto.negocio });
      return tx.usuario.create({
        data: {
          nombre: dto.nombre,
          email: dto.email,
          password: hash,
          rol: 'ADMIN',
          negocioId: negocio.id,
        },
      });
    });

    return {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
      negocioId: usuario.negocioId,
    };
  }

  listarVendedores(admin: UsuarioActual) {
    return this.prisma.usuario.findMany({
      where: { negocioId: admin.negocioId, rol: 'VENDEDOR' },
      select: { id: true, nombre: true, email: true, rol: true, creadoEn: true },
      orderBy: { nombre: 'asc' },
    });
  }

  async actualizarVendedor(id: number, dto: ActualizarVendedorDto, admin: UsuarioActual) {
    const vendedor = await this.prisma.usuario.findUnique({
      where: { id, negocioId: admin.negocioId, rol: 'VENDEDOR' },
    });
    if (!vendedor) throw new ConflictException('Vendedor no encontrado');

    const data: Record<string, unknown> = {};
    if (dto.nombre) data.nombre = dto.nombre;
    if (dto.email) data.email = dto.email;
    if (dto.password) data.password = await bcrypt.hash(dto.password, 10);

    const actualizado = await this.prisma.usuario.update({ where: { id }, data });
    return {
      id: actualizado.id,
      nombre: actualizado.nombre,
      email: actualizado.email,
      rol: actualizado.rol,
    };
  }

  async cambiarPassword(dto: CambiarPasswordDto, usuario: UsuarioActual) {
    const user = await this.prisma.usuario.findUnique({ where: { id: usuario.userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const valida = await bcrypt.compare(dto.passwordActual, user.password);
    if (!valida) throw new UnauthorizedException('La contraseña actual es incorrecta');

    const hash = await bcrypt.hash(dto.passwordNueva, 10);
    await this.prisma.usuario.update({ where: { id: usuario.userId }, data: { password: hash } });
    return { mensaje: 'Contraseña actualizada correctamente' };
  }

  async crearVendedor(dto: CrearVendedorDto, admin: UsuarioActual) {
    const existente = await this.prisma.usuario.findUnique({ where: { email: dto.email } });
    if (existente) throw new ConflictException('Ya existe un usuario con ese email');

    const hash = await bcrypt.hash(dto.password, 10);
    const usuario = await this.prisma.usuario.create({
      data: {
        nombre: dto.nombre,
        email: dto.email,
        password: hash,
        rol: 'VENDEDOR',
        negocioId: admin.negocioId,
      },
    });

    return {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
      negocioId: usuario.negocioId,
    };
  }
}
