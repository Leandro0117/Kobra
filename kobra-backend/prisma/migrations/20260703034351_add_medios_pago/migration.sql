-- AlterTable
ALTER TABLE "Venta" ADD COLUMN     "medioPagoId" INTEGER;

-- CreateTable
CREATE TABLE "MedioPago" (
    "id" SERIAL NOT NULL,
    "negocioId" INTEGER NOT NULL,
    "nombre" TEXT NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "esDefault" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "MedioPago_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "MedioPago" ADD CONSTRAINT "MedioPago_negocioId_fkey" FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Venta" ADD CONSTRAINT "Venta_medioPagoId_fkey" FOREIGN KEY ("medioPagoId") REFERENCES "MedioPago"("id") ON DELETE SET NULL ON UPDATE CASCADE;
