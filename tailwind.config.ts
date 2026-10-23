import type { Config } from 'tailwindcss';
export default { content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'], theme: { extend: { colors: { amparo: { yellow: '#FFD400', ink: '#0B0B0B', canvas: '#F7F7F5' } } } }, plugins: [] } satisfies Config;
