import { PrismaClient, Rol } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordAdmin = await bcrypt.hash('admin123', 10);
  const passwordVendedor = await bcrypt.hash('vendedor123', 10);

  const admin = await prisma.usuario.upsert({
    where: { email: 'admin@kobra.com' },
    update: {},
    create: {
      nombre: 'Administrador Kobra',
      email: 'admin@kobra.com',
      password: passwordAdmin,
      rol: Rol.ADMIN,
    },
  });

  const vendedor = await prisma.usuario.upsert({
    where: { email: 'vendedor@kobra.com' },
    update: {},
    create: {
      nombre: 'Vendedor de Prueba',
      email: 'vendedor@kobra.com',
      password: passwordVendedor,
      rol: Rol.VENDEDOR,
    },
  });

  const producto = await prisma.producto.upsert({
    where: { id: 1 },
    update: {},
    create: {
      nombre: 'Producto de prueba',
      variantes: {
        create: [{ nombre: 'Base', precio: 10 }],
      },
    },
    include: { variantes: true },
  });

  console.log('Seed completo:');
  console.log({ admin: admin.email, vendedor: vendedor.email, producto: producto.nombre });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
