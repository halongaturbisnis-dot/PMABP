import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';
import { tokens } from '../../ui/styles/tokens';

export const safeHtml2Canvas = async (element: HTMLElement, options: any = {}): Promise<HTMLCanvasElement> => {
  const activeRestorers: (() => void)[] = [];

  const oklchToRgb = (l: number, c: number, h: number, a: number = 1): string => {
    const hRad = (h * Math.PI) / 180;
    const L = l;
    const aVal = c * Math.cos(hRad);
    const bVal = c * Math.sin(hRad);
    
    const l_ = L + 0.3963377774 * aVal + 0.2118028117 * bVal;
    const m_ = L - 0.1055613458 * aVal - 0.0881400234 * bVal;
    const s_ = L - 0.0894841775 * aVal - 1.2914855480 * bVal;
    
    const l3 = l_ * l_ * l_;
    const m3 = m_ * m_ * m_;
    const s3 = s_ * s_ * s_;
    
    const rL = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
    const gL = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
    const bL = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;
    
    const rVal = rL <= 0.0031308 ? 12.92 * rL : 1.055 * Math.pow(rL, 1 / 2.4) - 0.055;
    const gVal = gL <= 0.0031308 ? 12.92 * gL : 1.055 * Math.pow(gL, 1 / 2.4) - 0.055;
    const bVal2 = bL <= 0.0031308 ? 12.92 * bL : 1.055 * Math.pow(bL, 1 / 2.4) - 0.055;
    
    const R = Math.max(0, Math.min(255, Math.round(rVal * 255)));
    const G = Math.max(0, Math.min(255, Math.round(gVal * 255)));
    const B = Math.max(0, Math.min(255, Math.round(bVal2 * 255)));
    
    return `rgba(${R}, ${G}, ${B}, ${a})`;
  };

  const parseOklchAndReplace = (cssString: string): string => {
    if (typeof cssString !== 'string') return cssString;
    let res = cssString;
    
    res = res.replace(/oklch\(\s*([\d.]+%?)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+%?))?\s*\)/gi, (match, lStr, sChr, sHue, sAlpha) => {
      try {
        const l = lStr.endsWith('%') ? parseFloat(lStr) / 100 : parseFloat(lStr);
        const c = parseFloat(sChr);
        const h = parseFloat(sHue);
        let a = 1;
        if (sAlpha) {
          a = sAlpha.endsWith('%') ? parseFloat(sAlpha) / 100 : parseFloat(sAlpha);
        }
        return oklchToRgb(l, c, h, a);
      } catch (e) {
        return 'rgba(71, 85, 105, 1)';
      }
    });

    res = res.replace(/oklch\(\s*([\d.]+%?)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+%?))?\s*\)/gi, (match, lStr, sChr, sHue, sAlpha) => {
      try {
        const l = lStr.endsWith('%') ? parseFloat(lStr) / 100 : parseFloat(lStr);
        const c = parseFloat(sChr);
        const h = parseFloat(sHue);
        let a = 1;
        if (sAlpha) {
          a = sAlpha.endsWith('%') ? parseFloat(sAlpha) / 100 : parseFloat(sAlpha);
        }
        return oklchToRgb(l, c, h, a);
      } catch (e) {
        return 'rgba(71, 85, 105, 1)';
      }
    });

    res = res.replace(/oklch\([^)]+\)/gi, 'rgba(71, 85, 105, 1)');
    res = res.replace(/(oklab|color-mix|display-p3|hwb)\([^)]+\)/gi, 'rgba(71, 85, 105, 1)');

    return res;
  };

  // 1. Intercept CSSRule.prototype.cssText
  const originalCssTextDescriptor = Object.getOwnPropertyDescriptor(CSSRule.prototype, 'cssText');
  if (originalCssTextDescriptor && originalCssTextDescriptor.get) {
    Object.defineProperty(CSSRule.prototype, 'cssText', {
      get() {
        const originalText = originalCssTextDescriptor.get!.call(this);
        return typeof originalText === 'string' ? parseOklchAndReplace(originalText) : originalText;
      },
      configurable: true
    });
    activeRestorers.push(() => {
      Object.defineProperty(CSSRule.prototype, 'cssText', originalCssTextDescriptor);
    });
  }

  // 2. Intercept CSSStyleDeclaration.prototype.cssText
  const originalDeclCssTextDescriptor = Object.getOwnPropertyDescriptor(CSSStyleDeclaration.prototype, 'cssText');
  if (originalDeclCssTextDescriptor && originalDeclCssTextDescriptor.get) {
    Object.defineProperty(CSSStyleDeclaration.prototype, 'cssText', {
      get() {
        const originalText = originalDeclCssTextDescriptor.get!.call(this);
        return typeof originalText === 'string' ? parseOklchAndReplace(originalText) : originalText;
      },
      configurable: true
    });
    activeRestorers.push(() => {
      Object.defineProperty(CSSStyleDeclaration.prototype, 'cssText', originalDeclCssTextDescriptor);
    });
  }

  // 3. Intercept CSSStyleDeclaration.prototype.getPropertyValue
  const originalGetPropertyValue = CSSStyleDeclaration.prototype.getPropertyValue;
  CSSStyleDeclaration.prototype.getPropertyValue = function(prop) {
    const val = originalGetPropertyValue.call(this, prop);
    return typeof val === 'string' ? parseOklchAndReplace(val) : val;
  };
  activeRestorers.push(() => {
    CSSStyleDeclaration.prototype.getPropertyValue = originalGetPropertyValue;
  });

  // 4. Intercept style elements textContent in memory
  const styleElements = Array.from(document.querySelectorAll('style'));
  const originalContents = styleElements.map(el => el.textContent || '');
  styleElements.forEach(el => {
    if (el.textContent && /oklch/gi.test(el.textContent)) {
      el.textContent = parseOklchAndReplace(el.textContent);
    }
  });
  activeRestorers.push(() => {
    styleElements.forEach((el, idx) => {
      el.textContent = originalContents[idx];
    });
  });

  // 5. Intercept common shorthand properties
  const originalPropertyDescriptors: Record<string, PropertyDescriptor> = {};
  const colorProps = ['color', 'backgroundColor', 'borderColor', 'borderTopColor', 'borderRightColor', 'borderBottomColor', 'borderLeftColor', 'outlineColor', 'fill', 'stroke'];
  colorProps.forEach(prop => {
    const desc = Object.getOwnPropertyDescriptor(CSSStyleDeclaration.prototype, prop);
    if (desc && desc.get) {
      originalPropertyDescriptors[prop] = desc;
      Object.defineProperty(CSSStyleDeclaration.prototype, prop, {
        get() {
          const val = desc.get!.call(this);
          return typeof val === 'string' ? parseOklchAndReplace(val) : val;
        },
        configurable: true
      });
    }
  });
  activeRestorers.push(() => {
    Object.keys(originalPropertyDescriptors).forEach(prop => {
      Object.defineProperty(CSSStyleDeclaration.prototype, prop, originalPropertyDescriptors[prop]);
    });
  });

  const customOnClone = (clonedDoc: Document) => {
    if (options.onclone) {
      options.onclone(clonedDoc);
    }

    const colorRegex = /(oklch|oklab|color-mix|display-p3|hwb)\([^)]+\)/g;
    const clonedStyles = clonedDoc.getElementsByTagName('style');
    for (let j = 0; j < clonedStyles.length; j++) {
      if (clonedStyles[j].innerHTML) {
        clonedStyles[j].innerHTML = parseOklchAndReplace(clonedStyles[j].innerHTML);
      }
    }

    const clonedElements = clonedDoc.getElementsByTagName('*');
    for (let j = 0; j < clonedElements.length; j++) {
      const el = clonedElements[j] as HTMLElement;
      if (el.style && el.style.cssText) {
        if (colorRegex.test(el.style.cssText)) {
          el.style.cssText = parseOklchAndReplace(el.style.cssText);
        }
      }
    }
  };

  const cleanOptions = {
    ...options,
    onclone: customOnClone
  };

  try {
    const res = await html2canvas(element, cleanOptions);
    return res;
  } finally {
    for (let i = activeRestorers.length - 1; i >= 0; i--) {
      try {
        activeRestorers[i]();
      } catch (e) {
        console.warn("Failed to restore property interceptor: ", e);
      }
    }
  }
};

/**
 * Helper to get CSS variable strings for light mode
 */
const getLightModeVariables = () => {
  let vars = '';
  const lightColors = tokens.colors.light;
  const lightText = tokens.textColors.light;
  const lightFeedback = tokens.feedbackColors.light;

  Object.entries(lightColors).forEach(([key, value]) => {
    vars += `--${key}: ${value}; `;
  });
  Object.entries(lightText).forEach(([key, value]) => {
    vars += `--${key}: ${value}; `;
  });
  Object.entries(lightFeedback).forEach(([key, value]) => {
    vars += `--${key}: ${value}; `;
  });

  return vars;
};

export const printPdf = (
  elementId: string, 
  customTitle: string = 'Document'
) => {
  const element = document.getElementById(elementId);
  if (!element) {
    console.error(`Element with id ${elementId} not found.`);
    return;
  }

  const printContents = element.outerHTML;
  // Sanitize contents to remove any "dark" classes and force "light"
  const sanitizedContents = printContents
    .replace(/\sdark\b/g, ' ')
    .replace(/"dark\b/g, '" ')
    .replace(/<([a-z0-9-]+)/i, '<$1 class="light" style="color-scheme: light !important;"');
  const lightVars = getLightModeVariables();

  let stylesHtml = '';
  // Clone all styles (Tailwind, imported CSS, etc)
  for (const node of Array.from(document.head.childNodes)) {
    if (node.nodeName === 'STYLE' || (node.nodeName === 'LINK' && (node as HTMLLinkElement).rel === 'stylesheet')) {
      stylesHtml += (node as Element).outerHTML;
    }
  }

  const printWindow = window.open('', '_blank');
  if (!printWindow) {
    alert("Please allow popups for this site to preview the PDF.");
    return;
  }

  printWindow.document.write(`
    <!DOCTYPE html>
    <html lang="en" class="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <title>${customTitle}</title>
        ${stylesHtml}
        <style>
          /* Deep forced light mode reset */
          :root {
            ${lightVars}
            color-scheme: light !important;
          }
          
          /* Prevent dark mode media queries from affecting the print window */
          @media (prefers-color-scheme: dark) {
            :root {
              ${lightVars}
              color-scheme: light !important;
            }
          }

          /* Ensure all dark: class variants are reset */
          .dark {
            background-color: var(--ColorBg) !important;
            color: var(--TextColorBase) !important;
          }
          
          /* Base print styles for robustness */
          @media print {
            * {
              -webkit-print-color-adjust: exact !important;
              print-color-adjust: exact !important;
            }
            body { 
              margin: 0;
            }
            @page {
              margin: 1.5cm;
              size: auto;
            }
            .no-print {
              display: none !important;
            }
          }
          
          /* Ensure light appearance */
          body {
            background-color: var(--ColorBg) !important;
            color: var(--TextColorBase) !important;
            padding: 2.5rem;
            max-width: 100%;
            min-height: 100vh;
          }

          #${elementId} {
            width: 100% !important;
            max-width: 800px !important; /* Slightly narrower for better A4-like flow */
            margin: 0 auto;
            display: block !important;
            background-color: var(--ColorBg) !important;
            color: var(--TextColorBase) !important;
            box-shadow: none !important;
            border: none !important;
          }
        </style>
      </head>
      <body class="light" style="background-color: var(--ColorBg) !important; color: var(--TextColorBase) !important;">
        <div id="print-wrapper" class="light" style="background-color: var(--ColorBg) !important; color: var(--TextColorBase) !important;">
          ${sanitizedContents}
        </div>
        <script>
          window.onload = function() {
            // Slight delay to ensure custom fonts and complex SVGs render
            setTimeout(() => {
               window.print();
            }, 800);
          }
        </script>
      </body>
    </html>
  `);
  printWindow.document.close();
};

export interface PdfExportOptions {
  filename?: string;
  multiPage?: boolean;
}

export const downloadPdf = async (elementId: string, options: PdfExportOptions = {}) => {
  const element = document.getElementById(elementId);
  if (!element) {
    console.error(`Element with id ${elementId} not found.`);
    return;
  }

  const { filename = 'document.pdf', multiPage = false } = options;

  try {
    const canvas = await safeHtml2Canvas(element, { 
      scale: 2.5, // Increased scale for crispiness
      useCORS: true, 
      backgroundColor: tokens.colors.light.ColorBg,
      windowWidth: 800, // Balanced width to match print styles
      onclone: (clonedDoc) => {
        // Force light mode variables and classes on the cloned document
        const root = clonedDoc.documentElement;
        root.classList.remove('dark');
        root.classList.add('light');
        root.style.colorScheme = 'light';
        root.style.backgroundColor = tokens.colors.light.ColorBg;
        root.style.color = tokens.textColors.light.TextColorBase;
        
        // Explicitly inject light mode variables into the cloned document
        const lightColors = tokens.colors.light;
        const lightText = tokens.textColors.light;
        const lightFeedback = tokens.feedbackColors.light;

        const allInjectedVars: Record<string, string> = {
          ...lightColors,
          ...lightText,
          ...lightFeedback
        };

        Object.entries(allInjectedVars).forEach(([key, value]) => {
          root.style.setProperty(`--${key}`, value as string, 'important');
        });
        
        // Force base background color on body of the clone
        const body = clonedDoc.body;
        body.style.backgroundColor = tokens.colors.light.ColorBg;
        body.style.color = tokens.textColors.light.TextColorBase;
        body.classList.remove('dark');
        body.classList.add('light');

        // More comprehensive color stripping regex for unsupported functions in html2canvas
        const colorRegex = /(oklch|oklab|color-mix|display-p3|hwb)\([^)]+\)/g;
        
        // 1. Strip from all style tags
        const styleTags = clonedDoc.getElementsByTagName('style');
        for (let i = 0; i < styleTags.length; i++) {
          styleTags[i].innerHTML = styleTags[i].innerHTML.replace(colorRegex, tokens.textColors.light.TextColorBase);
        }

        // 2. Strip from all inline styles and remove dark classes
        const allElements = clonedDoc.getElementsByTagName('*');
        for (let i = 0; i < allElements.length; i++) {
          const el = allElements[i] as HTMLElement;
          if (el.style && el.style.cssText) {
            if (colorRegex.test(el.style.cssText)) {
              el.style.cssText = el.style.cssText.replace(colorRegex, tokens.textColors.light.TextColorBase);
            }
          }
          
          if (el.classList.contains('dark')) {
            el.classList.remove('dark');
            el.classList.add('light');
          }
        }
      }
    });
    const imgData = canvas.toDataURL('image/png');
    
    const imgWidth = canvas.width;
    const imgHeight = canvas.height;

    if (multiPage) {
      // Standar kertas A4 (dalam pt/px, perbandingan resolusi).
      // Menggunakan unit px sehingga kompatibel dengan dimensi canvas.
      const A4_WIDTH = 595.28;
      const A4_HEIGHT = 841.89;
      
      // Hitung skala agar gambar pas di A4 width
      const ratio = A4_WIDTH / imgWidth;
      const scaledHeight = imgHeight * ratio;

      const pdf = new jsPDF({
        orientation: 'p',
        unit: 'pt',
        format: 'a4'
      });

      let heightLeft = scaledHeight;
      let position = 0;

      // Halaman pertama
      pdf.addImage(imgData, 'PNG', 0, position, A4_WIDTH, scaledHeight);
      heightLeft -= A4_HEIGHT;

      // Halaman tambahan
      while (heightLeft > 0) {
        position = heightLeft - scaledHeight; // Geser gambar ke atas
        pdf.addPage();
        pdf.addImage(imgData, 'PNG', 0, position, A4_WIDTH, scaledHeight);
        heightLeft -= A4_HEIGHT;
      }

      pdf.save(filename);
    } else {
      // PDF fleksibel, 1 halaman mengikuti dimensi konten
      const pdf = new jsPDF({
        orientation: imgWidth > imgHeight ? 'l' : 'p',
        unit: 'px',
        format: [imgWidth, imgHeight]
      });
      pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, imgHeight);
      pdf.save(filename);
    }
  } catch (err) {
    console.error("Error generating PDF", err);
    alert('Gagal membuat file PDF.');
  }
};
