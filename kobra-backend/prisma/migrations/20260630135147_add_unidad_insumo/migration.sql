/*
  Warnings:

  - The `unidad` column on the `Insumo` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- CreateEnum
CREATE TYPE "UnidadInsumo" AS ENUM ('UNIDAD', 'KG', 'G', 'L', 'ML', 'M', 'CM', 'PAQ', 'CAJA', 'DOC');

-- AlterTable
ALTER TABLE "Insumo" DROP COLUMN "unidad",
ADD COLUMN     "unidad" "UnidadInsumo";
