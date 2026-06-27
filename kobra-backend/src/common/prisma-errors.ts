import { Prisma } from '@prisma/client';

/**
 * Detecta violaciones de foreign key, ya sea que Prisma las reconozca como
 * PrismaClientKnownRequestError (P2003) o las exponga como un error de conector
 * sin tipar (ocurre con el RESTRICT que generan algunas versiones de Postgres/Neon).
 */
export function esErrorDeForeignKey(error: unknown): boolean {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2003') {
    return true;
  }
  const mensaje = error instanceof Error ? error.message : '';
  return /foreign key constraint|violates .* constraint/i.test(mensaje);
}
