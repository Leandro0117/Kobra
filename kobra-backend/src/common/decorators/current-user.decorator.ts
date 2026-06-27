import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface UsuarioActual {
  userId: number;
  email: string;
  rol: 'ADMIN' | 'VENDEDOR';
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): UsuarioActual => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
