const fs = require('fs');
const content = fs.readFileSync('src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx', 'utf8');
const bgClasses = content.match(/bg-[a-zA-Z0-9-]+/g) || [];
const borderClasses = content.match(/border-[a-zA-Z0-9-]+/g) || [];
const uniqueBg = [...new Set(bgClasses)].sort();
const uniqueBorder = [...new Set(borderClasses)].sort();
console.log("BG CLASSES:", uniqueBg.filter(c => c.match(/bg-(?:[a-z]+)-\d{2,3}/)));
console.log("BORDER CLASSES:", uniqueBorder.filter(c => c.match(/border-(?:[a-z]+)-\d{2,3}/)));
