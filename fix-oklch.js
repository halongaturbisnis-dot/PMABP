const fs = require('fs');

function fixFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf-8');

    // Remove opacities
    content = content.replace(/bg-slate-50\/50/g, "bg-slate-50");
    content = content.replace(/border-slate-200\/50/g, "border-slate-200");
    content = content.replace(/bg-slate-50\/30/g, "bg-slate-50");
    content = content.replace(/bg-gray-50\/50/g, "bg-gray-50");

    // We do NOT modify the backdrop color bg-slate-900/80 because it's not rendered in html2canvas!

    // Fix imports
    if (!content.includes('injectTailwindHexFallback')) {
      if (content.includes("from '../../../../logic/utils/pdf'")) {
        content = content.replace("from '../../../../logic/utils/pdf'", ", injectTailwindHexFallback } from '../../../../logic/utils/pdf'");
      } else {
        content = `import { injectTailwindHexFallback } from '../../../../logic/utils/pdf';\n` + content;
      }
    }

    const oncloneLogic = `
          onclone: (clonedDoc) => {
            const rootEl = clonedDoc.documentElement;
            if (rootEl) {
              rootEl.style.fontSize = '16px';
              injectTailwindHexFallback(rootEl);
            }
`;

    if (filePath.includes("PenjualanDetailPage")) {
        content = content.replace(/onclone:\s*\([^)]*\)\s*=>\s*\{[\s\S]*?const colorRegex[^}]*\}/g, oncloneLogic.trim());
        // Clean up the remaining style matching loop
        content = content.replace(/const styleTags[\s\S]*?border-box';\n\s*\}/g, `const clonedSheets = clonedDoc.querySelectorAll('.invoice-page-sheet');
            clonedSheets.forEach((sh) => {
              const el = sh as HTMLElement;
              el.style.width = '794px';
              el.style.height = '1123px';
              el.style.minWidth = '794px';
              el.style.maxWidth = '794px';
              el.style.minHeight = '1123px';
              el.style.maxHeight = '1123px';
              el.style.padding = '50px 60px';
              el.style.boxSizing = 'border-box';
              el.style.transform = 'none';
              el.style.margin = '0 auto';
            });
          }`);
    } else if (filePath.includes("PDFSuratJalan")) {
        // PDFSuratJalan has `onclone: fixHtml2CanvasOklch`
        content = content.replace(/const fixHtml2CanvasOklch = \([^)]*\) => \{[\s\S]*?\};/g, `const fixHtml2CanvasOklch = (clonedDoc: Document) => {
    const rootEl = clonedDoc.documentElement;
    if (rootEl) {
      injectTailwindHexFallback(rootEl);
    }
  };`);
    }

    fs.writeFileSync(filePath, content, 'utf-8');
}

fixFile('src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx');
fixFile('src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx');

