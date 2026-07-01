import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { Rol } from '@prisma/client';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { CrearVendedorDto } from './dto/crear-vendedor.dto';
import { Public } from '../common/decorators/public.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioActual } from '../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Public()
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // Registro público: crea un ADMIN junto con su negocio.
  @Public()
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Get('vendedores')
  @UseGuards(RolesGuard)
  @Roles(Rol.ADMIN)
  listarVendedores(@CurrentUser() admin: UsuarioActual) {
    return this.authService.listarVendedores(admin);
  }

  // Solo el ADMIN puede registrar vendedores en su negocio.
  @Post('vendedores')
  @UseGuards(RolesGuard)
  @Roles(Rol.ADMIN)
  crearVendedor(@Body() dto: CrearVendedorDto, @CurrentUser() admin: UsuarioActual) {
    return this.authService.crearVendedor(dto, admin);
  }
}
