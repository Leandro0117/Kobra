-- CreateTable: Variante (cada combinación de tamaño/topping de un Producto, con su propio precio)
CREATE TABLE "Variante" (
    "id" SERIAL NOT NULL,
    "productoId" INTEGER NOT NULL,
    "nombre" TEXT NOT NULL,
    "precio" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Variante_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Variante" ADD CONSTRAINT "Variante_productoId_fkey" FOREIGN KEY ("productoId") REFERENCES "Producto"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- DataMigration: cada Producto existente se convierte en una Variante "Base" con su precio actual,
-- para no perder el precio que ya estaba guardado en Producto.precio.
INSERT INTO "Variante" ("productoId", "nombre", "precio")
SELECT "id", 'Base', "precio" FROM "Producto";

-- AlterTable: agregar varianteId a DetalleVenta (todavía nullable, para poder rellenarlo)
ALTER TABLE "DetalleVenta" ADD COLUMN "varianteId" INTEGER;

-- DataMigration: cada DetalleVenta existente apuntaba a un Producto; ahora apunta a la
-- Variante "Base" que se creó para ese mismo Producto.
UPDATE "DetalleVenta" dv
SET "varianteId" = v."id"
FROM "Variante" v
WHERE v."productoId" = dv."productoId";

-- AlterTable: ahora que ya no hay nulls, varianteId pasa a ser obligatorio
ALTER TABLE "DetalleVenta" ALTER COLUMN "varianteId" SET NOT NULL;

-- DropForeignKey
ALTER TABLE "DetalleVenta" DROP CONSTRAINT "DetalleVenta_productoId_fkey";

-- AlterTable: se quita la columna vieja productoId de DetalleVenta
ALTER TABLE "DetalleVenta" DROP COLUMN "productoId";

-- AddForeignKey
ALTER TABLE "DetalleVenta" ADD CONSTRAINT "DetalleVenta_varianteId_fkey" FOREIGN KEY ("varianteId") REFERENCES "Variante"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AlterTable: el precio ahora vive en Variante, no en Producto
ALTER TABLE "Producto" DROP COLUMN "precio";
