-- CreateTable
CREATE TABLE "Negocio" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "nombre" TEXT NOT NULL,
    "direccion" TEXT,
    "telefono" TEXT,
    "moneda" TEXT NOT NULL,

    CONSTRAINT "Negocio_pkey" PRIMARY KEY ("id")
);
