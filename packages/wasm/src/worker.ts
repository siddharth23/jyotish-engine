/**
 * Web Worker entry point.
 *
 * Lets an application use the engine without importing it: the page starts this file
 * as a module worker and exchanges plain JSON messages with it. The application's own
 * code and this AGPL-3.0 engine then meet only at a message boundary, and the engine
 * runs off the main thread.
 *
 *   const worker = new Worker('/engine/worker.js', { type: 'module' });
 *   worker.postMessage({ id: 1, method: 'computeChart', args: [birthData] });
 *   worker.onmessage = ({ data }) => { data.id; data.result ?? data.error; };
 *
 * Methods mirror JyotishEngine. A `ready` message ({ id: 0, result: ENGINE_VERSION })
 * is posted once the WebAssembly module and ephemeris files have loaded, or
 * ({ id: 0, error }) if they could not be.
 */
import { ENGINE_VERSION, loadEngine, type JyotishEngine } from './index.js';

type Method =
  | 'computeChart'
  | 'computeDivisional'
  | 'computeDashas'
  | 'computePanchang'
  | 'computeTransits'
  | 'evaluateRules';

interface Request {
  readonly id: number;
  readonly method: Method;
  readonly args: readonly unknown[];
}

interface WorkerScope {
  postMessage(message: unknown): void;
  addEventListener(type: 'message', listener: (event: { data: Request }) => void): void;
}

const scope = globalThis as unknown as WorkerScope;
const METHODS: ReadonlySet<string> = new Set<Method>([
  'computeChart', 'computeDivisional', 'computeDashas', 'computePanchang', 'computeTransits', 'evaluateRules',
]);

const engine: Promise<JyotishEngine> = loadEngine({ assetBaseUrl: new URL('./native/', import.meta.url) });

engine.then(
  () => scope.postMessage({ id: 0, result: ENGINE_VERSION }),
  (error: unknown) => scope.postMessage({ id: 0, error: String(error instanceof Error ? error.message : error) }),
);

scope.addEventListener('message', (event) => {
  const { id, method, args } = event.data;
  void engine
    .then((instance) => {
      if (!METHODS.has(method)) throw new Error(`Unknown method "${String(method)}".`);
      const fn = instance[method] as (...a: unknown[]) => unknown;
      return fn.apply(instance, [...args]);
    })
    .then(
      (result) => scope.postMessage({ id, result }),
      (error: unknown) => scope.postMessage({ id, error: String(error instanceof Error ? error.message : error) }),
    );
});
