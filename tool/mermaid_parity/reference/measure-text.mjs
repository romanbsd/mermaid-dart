import fs from 'node:fs';
import puppeteer from 'puppeteer';

const executablePath = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
].find((path) => path && fs.existsSync(path));

if (!executablePath) {
  throw new Error('Chrome or Chromium is required to measure Mermaid SVG text; set CHROME_PATH if it is not installed in a standard location');
}
if (process.argv.length < 3) {
  throw new Error('Usage: node measure-text.mjs SVG...');
}

const browser = await puppeteer.launch({
  executablePath,
  headless: true,
  args: ['--no-sandbox'],
});

try {
  const page = await browser.newPage();
  const result = {};
  for (const path of process.argv.slice(2)) {
    await page.setContent(fs.readFileSync(path, 'utf8'));
    await page.evaluate(() => document.fonts.ready);
    result[path] = await page.evaluate(() =>
      [...document.querySelectorAll('.architecture-service')].flatMap((service) => {
        const text = service.querySelector('text');
        if (!text) return [];
        const label = [...text.querySelectorAll('.text-inner-tspan')].map((part) => part.textContent).join('');
        const {width, height} = text.getBBox();
        return [{label, width, height}];
      }),
    );
  }
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} finally {
  await browser.close();
}
