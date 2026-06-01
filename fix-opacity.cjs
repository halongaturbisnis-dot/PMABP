const fs = require('fs');

function removeOpacity(filePath) {
    let content = fs.readFileSync(filePath, 'utf-8');

    // PenjualanDetailPage
    content = content.replace(/className="([^"]*)bg-([a-z]+)-([0-9]{2,3})\/[0-9]{2,3}([^"]*)"/g, 'className="$1bg-$2-$3$4"');
    content = content.replace(/className="([^"]*)border-([a-z]+)-([0-9]{2,3})\/[0-9]{2,3}([^"]*)"/g, 'className="$1border-$2-$3$4"');

    // We only want to avoid replacing the active modal background which is `bg-slate-900/80` or similar
    // Actually, html2canvas doesn't crash on `bg-slate-900/80` because it's OUTSIDE the captured element!
    // But let's just restore that one just in case we hit it.
    content = content.replace(/bg-slate-900"/g, 'bg-slate-900/80"'); // Wait, let's just make it simpler

    fs.writeFileSync(filePath, content, 'utf-8');
}

removeOpacity('src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx');
removeOpacity('src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx');

