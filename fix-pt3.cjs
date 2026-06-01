const fs = require('fs');

function fixFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf-8');

    // Fix imports
    if (!content.includes('injectTailwindHexFallback')) {
      content = `import { injectTailwindHexFallback } from '../../../../logic/utils/pdf';\n` + content;
    }

    content = content.replace(/const fixHtml2CanvasOklch = \([^)]*\) => \{[\s\S]*?\};\n\n/g, `const fixHtml2CanvasOklch = (clonedDoc: Document) => {
    const rootEl = clonedDoc.documentElement;
    if (rootEl) {
      injectTailwindHexFallback(rootEl);
    }
  };\n\n`);

    fs.writeFileSync(filePath, content, 'utf-8');
}

fixFile('src/modules/penjualan/penyerahan/components/PDFSuratJalan.tsx');
