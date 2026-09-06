// Flutter 3.47.2's Windows browser-test server converts URL paths to backslashes,
// then tests startsWith('canvaskit/'), returning 404 for its bundled renderer.
// This test-only adapter fulfills those requests from the SAME SDK. It does not
// modify the shared SDK, production assets, personal browser, or player storage.
import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

const flutter = path.resolve(process.argv[2] ?? '');
if (path.basename(flutter).toLowerCase() !== 'flutter.bat') {
  throw new Error('Pass the absolute path to the pinned flutter.bat.');
}
const sdk = path.dirname(path.dirname(flutter));
const renderer = path.join(sdk, 'bin/cache/flutter_web_sdk/canvaskit');
const child = spawn(path.join(sdk, 'bin/cache/dart-sdk/bin/dart.exe'), [
  `--packages=${path.join(sdk, 'packages/flutter_tools/.dart_tool/package_config.json')}`,
  path.join(sdk, 'bin/cache/flutter_tools.snapshot'), 'test', '--platform', 'chrome',
  'test/save_import_browser_test.dart', '--verbose',
], { windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
let attached = false, buffer = '', socket, nextId = 0;
const tail = [];
let inFailure = false;
const pending = new Map();
function send(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
async function attach(port) {
  const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const tab = tabs.find(t => t.type === 'page' && t.url.startsWith('http://localhost:'));
  if (!tab) throw new Error('Disposable Flutter test tab not found.');
  socket = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
  socket.onmessage = async event => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const waiter = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) waiter?.reject(new Error(message.error.message));
      else waiter?.resolve(message.result);
      return;
    }
    if (message.method !== 'Fetch.requestPaused') return;
    const { requestId, request } = message.params;
    try {
      const relative = new URL(request.url).pathname.slice('/canvaskit/'.length);
      const file = path.resolve(renderer, relative);
      if (!file.startsWith(renderer + path.sep) || !/\.(js|wasm)$/.test(file)) {
        throw new Error('Unexpected renderer path.');
      }
      const bytes = await readFile(file);
      await send('Fetch.fulfillRequest', { requestId, responseCode: 200,
        responseHeaders: [{ name: 'Content-Type', value: file.endsWith('.wasm') ? 'application/wasm' : 'text/javascript' }],
        body: bytes.toString('base64'),
      });
    } catch (error) {
      console.error('Renderer adapter:', error.message);
      await send('Fetch.failRequest', { requestId, errorReason: 'Failed' });
    }
  };
  await send('Fetch.enable', { patterns: [{ urlPattern: 'http://localhost:*/canvaskit/*', requestStage: 'Request' }] });
  // The initial page may already have seen a 404 before DevTools was announced.
  await send('Page.reload', { ignoreCache: true });
  console.log('Test-only SDK renderer adapter attached.');
}
function output(chunk) {
  buffer += chunk.toString();
  const lines = buffer.split(/\r?\n/);
  buffer = lines.pop();
  for (const line of lines) {
    tail.push(line);
    if (tail.length > 80) tail.shift();
    if (/^\d\d:\d\d /.test(line)) inFailure = line.endsWith('[E]');
    if (inFailure || /^\d\d:\d\d |Error:|error:|Exception|failed|passed/.test(line)) console.log(line);
    const match = line.match(/DevTools listening on ws:\/\/127\.0\.0\.1:(\d+)\//);
    if (match && !attached) {
      attached = true;
      attach(match[1]).catch(error => { console.error(error); stop(); });
    }
  }
}
function stop() {
  // Only the process tree created above, never a user's browser or SDK service.
  spawn('taskkill.exe', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
}
child.stdout.on('data', output);
child.stderr.on('data', output);
const timeout = setTimeout(() => { console.error('Disposable browser test timed out.'); stop(); }, 180000);
child.on('exit', code => {
  clearTimeout(timeout);
  socket?.close();
  if (code !== 0) console.error(tail.join('\n'));
  process.exitCode = code ?? 1;
});
process.on('SIGINT', stop);
