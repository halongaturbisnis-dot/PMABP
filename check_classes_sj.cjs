const fs = require('fs');
const content = fs.readFileSync('src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx', 'utf8');
const textClasses = content.match(/text-[a-zA-Z0-9-]+/g) || [];
const bgClasses = content.match(/bg-[a-zA-Z0-9-]+/g) || [];
const borderClasses = content.match(/border-[a-zA-Z0-9-]+/g) || [];
const uniqueAll = [...new Set([...textClasses, ...bgClasses, ...borderClasses])].sort();
console.log("ALL COLOR CLASSES:", uniqueAll.filter(c => c.match(/(text|bg|border)-(?:[a-z]+)-\d{2,3}/)));
