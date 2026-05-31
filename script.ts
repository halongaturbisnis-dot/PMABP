import * as fs from 'fs';
let file = 'src/ui/components/elements/Dropdown.tsx';
let data = fs.readFileSync(file, 'utf8');

data = data.replace(/className="flex-1 bg-transparent text-FontSizeNano sm:text-FontSizeSm focus:outline-none text-TextColorBase font-medium"/g, "className={cn('flex-1 bg-transparent focus:outline-none text-TextColorBase font-medium', isMobile ? 'text-FontSizeNano' : 'text-FontSizeSm')}");

data = data.replace(/"text-TextColorMuted font-medium text-FontSizeNano sm:text-FontSizeSm"/g, "cn('text-TextColorMuted font-medium', isMobile ? 'text-FontSizeNano' : 'text-FontSizeSm')");

data = data.replace(/className="px-SpacingSmall py-SpacingLarge text-center text-TextColorMuted text-FontSizeNano sm:text-FontSizeSm italic font-medium"/g, "className={cn('px-SpacingSmall py-SpacingLarge text-center text-TextColorMuted italic font-medium', isMobile ? 'text-FontSizeNano' : 'text-FontSizeSm')}");

data = data.replace(/"flex items-center justify-between px-SpacingSmall py-SpacingSmall rounded-RadiusMedium text-FontSizeNano sm:text-FontSizeSm cursor-pointer transition-all duration-DurationFast"/g, "cn('flex items-center justify-between px-SpacingSmall py-SpacingSmall rounded-RadiusMedium cursor-pointer transition-all duration-DurationFast', isMobile ? 'text-FontSizeNano' : 'text-FontSizeSm')");

data = data.replace(/"flex min-h-spacing-SpacingHuge w-full flex-wrap items-center gap-SpacingTiny rounded-RadiusLarge border border-ColorSidebarBorder\/opacity-OpacitySubtle bg-ColorBg px-SpacingTiny py-SpacingTiny text-FontSizeNano sm:text-FontSizeSm cursor-pointer shadow-ElevationLow hover:border-ColorSidebarBorder transition-all duration-DurationFast"/g, "cn('flex min-h-spacing-SpacingHuge w-full flex-wrap items-center gap-SpacingTiny rounded-RadiusLarge border border-ColorSidebarBorder/opacity-OpacitySubtle bg-ColorBg px-SpacingTiny py-SpacingTiny cursor-pointer shadow-ElevationLow hover:border-ColorSidebarBorder transition-all duration-DurationFast', isMobile ? 'text-FontSizeNano' : 'text-FontSizeSm')");

fs.writeFileSync(file, data);
console.log('Script done');
