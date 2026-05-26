import sharp from "sharp";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const input = join(root, "images", "logo.png");
const output = join(root, "images", "logo-transparent.png");

function alphaFromPixel(r, g, b) {
  const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  const maxC = Math.max(r, g, b);
  const minC = Math.min(r, g, b);
  const chroma = maxC - minC;

  // Почти чёрный фон
  if (lum < 22 && maxC < 32) return 0;

  // Тёмные участки без яркого свечения (пыль фона)
  if (lum < 48 && chroma < 55 && maxC < 70) {
    const t = (48 - lum) / 48;
    return Math.round(255 * (1 - Math.min(1, t * 1.1)));
  }

  // Мягкий переход у краёв ореола на фоне
  if (lum < 72 && chroma < 35) {
    const t = (72 - lum) / 72;
    return Math.round(255 * (1 - t * 0.75));
  }

  return 255;
}

const { data, info } = await sharp(input)
  .ensureAlpha()
  .raw()
  .toBuffer({ resolveWithObject: true });

const { width, height, channels } = info;

for (let i = 0; i < width * height; i++) {
  const idx = i * channels;
  const r = data[idx];
  const g = data[idx + 1];
  const b = data[idx + 2];
  const a = alphaFromPixel(r, g, b);
  data[idx + 3] = Math.min(data[idx + 3], a);
}

await sharp(data, { raw: { width, height, channels } })
  .png({ compressionLevel: 9 })
  .toFile(output);

const trimmed = await sharp(output).trim({ threshold: 10 }).toBuffer();
await sharp(trimmed).png().toFile(output);

console.log("Saved:", output);
