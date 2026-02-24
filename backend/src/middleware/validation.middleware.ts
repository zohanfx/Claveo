import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

export function validate(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const result = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      // Assign parsed/coerced values back to request
      if (result && typeof result === 'object') {
        const r = result as Record<string, unknown>;
        if (r.body) req.body = r.body;
        if (r.query) req.query = r.query as typeof req.query;
        if (r.params) req.params = r.params as typeof req.params;
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}
