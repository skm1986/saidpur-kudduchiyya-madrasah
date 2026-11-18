import 'dotenv/config';
import express from 'express';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { apiRouter } from './src/server/routes.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const httpServer = http.createServer(app);
  const PORT = Number(process.env.PORT || 3000);

  app.use(express.json({ limit: '25mb' }));
  const downloadHeaders = (res: express.Response, filePath: string) => {
    const ext = path.extname(filePath).toLowerCase();
    const baseName = path.basename(filePath);
    if (ext === '.zip') res.setHeader('Content-Type', 'application/zip');
    else if (ext === '.pdf') res.setHeader('Content-Type', 'application/pdf');
    else if (ext === '.md') res.setHeader('Content-Type', 'text/markdown; charset=utf-8');
    else if (ext === '.json') res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${baseName}"`);
  };
  app.use(
    '/downloads',
    express.static(path.join(__dirname, 'public', 'downloads'), { setHeaders: downloadHeaders })
  );
  app.use(
    '/downloads',
    express.static(path.join(__dirname, 'dist', 'downloads'), { setHeaders: downloadHeaders })
  );
  app.use('/downloads', (_req, res) => {
    res.status(404).json({ error: 'Downloadable package file not found.' });
  });
  app.use('/api', apiRouter);

  if (process.env.NODE_ENV === 'production') {
    const distDir = path.join(__dirname, 'dist');
    app.use(express.static(distDir));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distDir, 'index.html'));
    });
  } else {
    const { createServer: createViteServer } = await import('vite');
    const hmrDisabled = process.env.DISABLE_HMR === 'true';
    const vite = await createViteServer({
      server: {
        middlewareMode: true,
        hmr: hmrDisabled ? false : { server: httpServer },
        ws: hmrDisabled ? false : undefined,
      },
      appType: 'spa',
    });

    if (hmrDisabled) {
      app.get('/@vite/client', async (_req, res, next) => {
        try {
          const transformed = await vite.transformRequest('/@vite/client');
          if (!transformed?.code) {
            return next();
          }
          const patched = transformed.code
            .replace('ws.send(JSON.stringify(data));', 'if (ws && ws.readyState === 1) ws.send(JSON.stringify(data));')
            .replace(/throw new SendBeforeConnectError\([^)]*\);?/g, 'return;')
            .replace('transport.connect(createHMRHandler(handleMessage));', '/* HMR WebSocket disabled */')
            .replace('setupForwardConsoleHandler(transport, forwardConsole);', '/* Console forwarding disabled */');
          res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
          res.send(patched);
        } catch (err) {
          next(err);
        }
      });
    }

    app.use(vite.middlewares);
  }

  httpServer.listen(PORT, '0.0.0.0', () => {
    console.log(`Saidpur kudduchiyya madrasah Membership Server listening on http://localhost:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error('Fatal server startup error:', err);
  process.exit(1);
});
