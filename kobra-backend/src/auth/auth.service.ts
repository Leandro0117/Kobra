import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { UsuarioActual } from '../common/decorators/current-user.decorator';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { CrearVendedorDto } from './dto/crear-vendedor.dto';

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
