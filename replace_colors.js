const fs = require('fs');

const files = [
  'src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx',
  'src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx'
];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  
  // Replace slate-100 to Slate100, etc.
  content = content.replace(/slate-(\d{2,3})/g, 'Slate$1');
  
  // Replace gray-100 to Slate100 as well
  content = content.replace(/gray-(\d{2,3})/g, 'Slate$1');

  fs.writeFileSync(file, content, 'utf8');
  console.log(`Replaced colors in ${file}`);
}
