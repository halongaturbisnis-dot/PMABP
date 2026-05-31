import * as fs from 'fs';
import * as path from 'path';

function replaceContent(content: string) {
    return content
        .replace(/liabilitas/g, 'piutang')
        .replace(/Liabilitas/g, 'Piutang')
        .replace(/LIABILITAS/g, 'PIUTANG')
        .replace(/purchase_id/g, 'sales_id')
        .replace(/purchase/g, 'sales') // Need to be careful here? Nah, these are mostly variables
        .replace(/Hutang/g, 'Piutang')
        .replace(/hutang/g, 'piutang')
        .replace(/Pengeluaran/g, 'Pemasukan')
        .replace(/pengeluaran/g, 'pemasukan');
}

const sourceFolder = path.join(process.cwd(), 'src/modules/Finansial/Liabilitas/pages');
const destFolder = path.join(process.cwd(), 'src/modules/Finansial/Piutang/pages');

if (!fs.existsSync(destFolder)) {
    fs.mkdirSync(destFolder, { recursive: true });
}

fs.readdirSync(sourceFolder).forEach(file => {
    if (file.endsWith('.tsx')) {
        const sourcePath = path.join(sourceFolder, file);
        const destPath = path.join(destFolder, file.replace('Liabilitas', 'Piutang'));
        const content = fs.readFileSync(sourcePath, 'utf8');
        fs.writeFileSync(destPath, replaceContent(content));
        console.log(`Generated ${destPath}`);
    }
});
