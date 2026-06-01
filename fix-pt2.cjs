const fs = require('fs');

function fixFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf-8');

    const targetRegexOld = /const colorRegex[\s\S]*?\}[\s\S]*?\}/g;
    content = content.replace(/const colorRegex[^]*?\}\s*\}/g, '  }');
    
    // now we need to inject injectTailwindHexFallback
    content = content.replace(/rootEl\.style\.fontSize = '16px';/g, "rootEl.style.fontSize = '16px';\n              injectTailwindHexFallback(rootEl);");

    fs.writeFileSync(filePath, content, 'utf-8');
}

fixFile('src/modules/penjualan/penjualan/pages/PenjualanDetailPage.tsx');
