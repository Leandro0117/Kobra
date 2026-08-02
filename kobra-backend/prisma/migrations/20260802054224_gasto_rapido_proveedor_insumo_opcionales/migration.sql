-- DropForeignKey
ALTER TABLE "DetalleGasto" DROP CONSTRAINT "DetalleGasto_insumoId_fkey";

-- DropForeignKey
ALTER TABLE "Gasto" DROP CONSTRAINT "Gasto_proveedorId_fkey";

-- AlterTable
ALTER TABLE "DetalleGasto" ADD COLUMN     "concepto" TEXT,
ALTER COLUMN "insumoId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "Gasto" ALTER COLUMN "proveedorId" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "Gasto" ADD CONSTRAINT "Gasto_proveedorId_fkey" FOREIGN KEY ("proveedorId") REFERENCES "Proveedor"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DetalleGasto" ADD CONSTRAINT "DetalleGasto_insumoId_fkey" FOREIGN KEY ("insumoId") REFERENCES "Insumo"("id") ON DELETE SET NULL ON UPDATE CASCADE;
