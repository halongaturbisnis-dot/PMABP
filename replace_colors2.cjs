const fs = require('fs');

const files = [
  'src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx',
  'src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx'
];

const colorMap = {
  'red-600': '#dc2626',
  'red-700': '#b91c1c',
  'amber-700': '#b45309',
  'emerald-600': '#059669',
  'emerald-700': '#047857',
  'green-600': '#16a34a',
  'green-700': '#15803d',
  'orange-600': '#ea580c',
  'teal-600': '#0d9488',
  'blue-600': '#2563eb',
  'fuchsia-600': '#c026d3',
};

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  
  // Create a regex to match these specific color classes when used as text-*
  for (const [cls, hex] of Object.entries(colorMap)) {
    // replace `text-red-600` with class-less inline style...
    // simpler: just remove `text-red-600` and it will fallback to Slate900.
    // Let's just replace `text-${cls}` with `text-Slate900`!
    content = content.replace(new RegExp(`text-${cls}`, 'g'), 'text-Slate900');
    content = content.replace(new RegExp(`bg-${cls}`, 'g'), 'bg-Slate100');
    content = content.replace(new RegExp(`border-${cls}`, 'g'), 'border-Slate300');
  }

  // Also catch any missed gray-, neutral-, stone- -> Slate
  content = content.replace(/neutral-(\d{2,3})/g, 'Slate$1');
  content = content.replace(/stone-(\d{2,3})/g, 'Slate$1');
  content = content.replace(/zinc-(\d{2,3})/g, 'Slate$1');

  fs.writeFileSync(file, content, 'utf8');
  console.log(`Replaced additional colors in ${file}`);
}
