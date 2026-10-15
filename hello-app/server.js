import { createServer } from "node:http";

const port = Number(process.env.PORT ?? 8080);
const revision = process.env.K_REVISION ?? "local";

createServer((req, res) => {
  res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
  res.end(`Hello, IaC study!\nrevision: ${revision}\n`);
}).listen(port, () => {
  console.log(`listening on :${port}`);
});
