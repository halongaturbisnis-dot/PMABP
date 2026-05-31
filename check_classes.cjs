const fs = require('fs');
const content = fs.readFileSync('src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx', 'utf8');
const textClasses = content.match(/text-[a-zA-Z0-9-]+/g) || [];
const uniqueClasses = [...new Set(textClasses)].sort();
console.log("TEXT CLASSES:", uniqueClasses.filter(c => c.match(/text-(?:[a-z]+)-\d{2,3}/)));
