import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { ClientesModule } from './clientes/clientes.module';
import { ProductosModule } from './productos/productos.module';
import { VariantesModule } from './variantes/variantes.module';
import { VentasModule } from './ventas/ventas.module';
import { EstadisticasModule } from './estadisticas/estadisticas.module';
import { ProveedoresModule } from './proveedores/proveedores.module';
import { InsumosModule } from './insumos/insumos.module';
import { GastosModule } from './gastos/gastos.module';
import { FinanzasModule } from './finanzas/finanzas.module';
import { NegocioModule } from './negocio/negocio.module';
import { HealthModule } from './health/health.module';
import { JwtAuthGuard } from './auth/jwt-auth.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    ClientesModule,
    ProductosModule,
    VariantesModule,
    VentasModule,
    EstadisticasModule,
    ProveedoresModule,
    InsumosModule,
    GastosModule,
    FinanzasModule,
    NegocioModule,
    HealthModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
