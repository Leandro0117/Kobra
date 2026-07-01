-- Paso 1: Convertir Negocio de singleton a tabla normal con autoincrement.
-- El registro existente (id=1) queda como el negocio de todos los datos actuales.
CREATE SEQUENCE negocio_id_seq START 2;
ALTER TABLE "Negocio" ADD COLUMN "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       ALTER COLUMN "id" SET DEFAULT nextval('negocio_id_seq');
ALTER SEQUENCE negocio_id_seq OWNED BY "Negocio"."id";

-- Paso 2: Agregar negocioId como nullable en todas las tablas.
ALTER TABLE "Usuario"   ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Cliente"   ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Producto"  ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Venta"     ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Proveedor" ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Insumo"    ADD COLUMN "negocioId" INTEGER;
ALTER TABLE "Gasto"     ADD COLUMN "negocioId" INTEGER;

-- Paso 3: Asignar el negocio existente (id=1) a todos los registros actuales.
UPDATE "Usuario"   SET "negocioId" = 1;
UPDATE "Cliente"   SET "negocioId" = 1;
UPDATE "Producto"  SET "negocioId" = 1;
UPDATE "Venta"     SET "negocioId" = 1;
UPDATE "Proveedor" SET "negocioId" = 1;
UPDATE "Insumo"    SET "negocioId" = 1;
UPDATE "Gasto"     SET "negocioId" = 1;

-- Paso 4: Hacer las columnas NOT NULL.
ALTER TABLE "Usuario"   ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Cliente"   ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Producto"  ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Venta"     ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Proveedor" ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Insumo"    ALTER COLUMN "negocioId" SET NOT NULL;
ALTER TABLE "Gasto"     ALTER COLUMN "negocioId" SET NOT NULL;

-- Paso 5: Agregar claves foráneas.
ALTER TABLE "Usuario"   ADD CONSTRAINT "Usuario_negocioId_fkey"   FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Cliente"   ADD CONSTRAINT "Cliente_negocioId_fkey"   FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Producto"  ADD CONSTRAINT "Producto_negocioId_fkey"  FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Venta"     ADD CONSTRAINT "Venta_negocioId_fkey"     FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Proveedor" ADD CONSTRAINT "Proveedor_negocioId_fkey" FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Insumo"    ADD CONSTRAINT "Insumo_negocioId_fkey"    FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Gasto"     ADD CONSTRAINT "Gasto_negocioId_fkey"     FOREIGN KEY ("negocioId") REFERENCES "Negocio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
