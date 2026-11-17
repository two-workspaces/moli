# Deploy and Host Moli on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/moli?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=moli)

[Moli](https://github.com/lexmount/moli) is an open-source headless browser built for AI agents, written in Rust by Lexmount. It isn't a Chromium wrapper. It's its own engine with V8, a real DOM, CSS, fetch, cookies and storage. It skips layout and painting until something actually needs pixels, such as a screenshot or a click at coordinates. One binary speaks CDP, WebDriver Classic and WebDriver BiDi, so Playwright, Puppeteer, Selenium, browser-use and Stagehand can drive it as if it were Chrome. On Railway it idles at about 15 MB of RAM.

## About Hosting Moli

It's one service and needs no database or volume. Moli runs `moli serve` on localhost inside the container. A small Caddy gate in front of it is the only thing on your Railway domain.

- **Token-protected from the first second.** Moli has no login of its own, and an open automation port is a free remote browser for anyone who finds it. The gate rejects every request without `MOLI_TOKEN`, which is generated at deploy. The token can arrive as a bearer header, a `?token=` query parameter, or a basic-auth password, so every kind of client can pass it.
- **No access to your private network.** Moli starts with `--block-private-networks`. Pages and scripts can't reach `*.railway.internal`, other private IP ranges, the cloud metadata address, or the browser's own control port. Tested on Railway.
- **Works with `connectOverCDP` out of the box.** Moli tells clients to connect to `ws://127.0.0.1:9222`. The gate rewrites `/json/version` so that Playwright and Puppeteer get your public `wss://` address instead.
- **Screenshots on.** `MOLI_ARGS` defaults to `--layout`, so screenshots, element boxes and coordinate clicks work. Layout still runs only when a request needs it.
- **Pinned release.** The image downloads Moli `v1.1.25`. To upgrade, change `MOLI_VERSION` in the Dockerfile of your fork.

## Common Use Cases

- A remote browser for browser-use, Stagehand, LangChain or your own Playwright agents, without running Chrome on your laptop or paying per browser-minute
- Scraping and extraction: render JavaScript-heavy pages, then read the DOM, text or HTML
- Screenshot and PDF services, link previews and page monitoring for apps already hosted on Railway

## Dependencies for Moli Hosting

- Nothing else: no database, no volume, no Chrome
- A CDP or WebDriver client: Playwright, Puppeteer, Selenium, browser-use, Stagehand or plain WebSockets

### Deployment Dependencies

- [Moli on GitHub](https://github.com/lexmount/moli)
- [Template source on GitHub](https://github.com/two-workspaces/moli)

### Implementation Details

Copy `MOLI_TOKEN` from the service's Variables tab. Replace `<your-domain>` with the service's Railway domain.

**Playwright (Node).** Use the header form:

```js
import { chromium } from "playwright";

const browser = await chromium.connectOverCDP("https://<your-domain>", {
  headers: { Authorization: `Bearer ${process.env.MOLI_TOKEN}` },
});
const context = await browser.newContext();
const page = await context.newPage();
await page.goto("https://example.com");
console.log(await page.title());
await browser.close();
```

**Playwright (Python), Puppeteer and browser-use.** Tools that take just a URL can use the query form: `https://<your-domain>/?token=<MOLI_TOKEN>`. Tools that need a raw WebSocket can use `wss://<your-domain>/devtools/browser/moli-browser?token=<MOLI_TOKEN>`. For Puppeteer, that's `puppeteer.connect({ browserWSEndpoint })`.

```python
browser = await p.chromium.connect_over_cdp("https://<your-domain>/?token=<MOLI_TOKEN>")
```

**Selenium (WebDriver Classic).** Use basic auth with the username `moli` and the token as the password. Use plain options with the browser name `moli`, not `ChromeOptions`:

```python
from selenium import webdriver
from selenium.webdriver.common.options import ArgOptions
from selenium.webdriver.remote.client_config import ClientConfig

url = "https://<your-domain>"
options = ArgOptions()
options.set_capability("browserName", "moli")
driver = webdriver.Remote(
    command_executor=url,
    options=options,
    client_config=ClientConfig(remote_server_addr=url, username="moli", password=MOLI_TOKEN),
)
```

**Tuning.** `MOLI_ARGS` is passed to `moli serve`:

- Add `--resource` to load images, fonts and media. By default these are skipped, which saves bandwidth and time.
- Use `--http-proxy socks5://...` to send traffic through a proxy.
- Use `--user-agent "..."` to set a custom user agent.
- Remove `--layout` to run in pure DOM mode. That uses the least CPU, but screenshots come back blank.

Run `moli serve --help` for the full list.

**Health.** `/health` is the only path that works without the token. Railway uses it as the healthcheck.

**Resources.** Measured on Railway:

- **Idle:** about 15 MB of RAM.
- **Under load:** six pages loading in parallel in separate contexts, each taking a screenshot, peaked at about 330 MB of RAM and 1.3 vCPU.
- **After load:** memory settled back to about 120 MB once the contexts closed.

That fits every Railway plan, including Free. Moli is newer than Chrome, so some complex web apps may still render or behave differently.

## Why Deploy Moli on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Moli on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
