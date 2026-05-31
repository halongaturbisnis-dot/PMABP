import React from 'react';
import { Link } from 'react-router-dom';
import { useGlobalState } from '../../../logic/context/GlobalContext';
import { Bell, Search, Layout, Layers } from 'lucide-react';
import { GhostButton } from '../elements/Button';
import { appAssets } from '../../styles/assets';
import { cn } from '../../../logic/utils/cn';

export const Header: React.FC = () => {
  const { state, toggleSidebarMode, setSidebarCollapsed } = useGlobalState();
  const { viewport, sidebarMode, isSidebarCollapsed } = state;

  return (
    <header className="h-14 flex items-center justify-between z-ZSticky">
      {/* Left Side: Empty or Breadcrumbs */}
      <div className="flex items-center gap-SpacingBase flex-1" />

      {/* Center Side: Company Info */}
      <div className="flex flex-col items-center leading-tight">
        <span 
          className={cn(
            "font-black bg-clip-text !text-ColorPrimary text-center",
            viewport.isCompact ? "!text-[0.95rem]" : "!text-[1.5rem] !text-ColorPrimary"
          )}
        >
          {appAssets.AppName}
        </span>
      </div>

      {/* Right Side: Actions & Profile */}
      <div className="flex items-center justify-end flex-1 gap-2">
        <GhostButton 
          size="sm" 
          onClick={toggleSidebarMode}
          className="hidden w-7 h-7 rounded-RadiusFull"
          title={sidebarMode === 'fluid' ? 'Switch to Floating' : 'Switch to Fluid'}
        >
          {sidebarMode === 'fluid' ? <Layout size={18} className="text-TextColorMuted" /> : <Layers size={18} className="text-ColorPrimary" />}
        </GhostButton>

        <GhostButton size="sm" className="hidden w-7 h-7 rounded-RadiusFull relative">
          <Bell size={18} className="text-TextColorMuted" />
          <span className="absolute top-2.5 right-2.5 w-1.5 h-1.5 bg-red-500 rounded-RadiusFull border-BorderThin border-White" />
        </GhostButton>
        
        <Link to="/profile" className="flex items-center justify-center w-7 h-7 hover:bg-black/5 rounded-RadiusFull transition-colors group overflow-hidden">
          <div className="w-7 h-7 rounded-RadiusFull bg-ColorPrimary/0 flex items-center justify-center border border-ColorPrimary/20 overflow-hidden">
            <img 
              src={state.user?.foto_profil || appAssets.AccountPlaceholder} 
              alt="Profile" 
              className="w-full h-full object-cover" 
            />
          </div>
        </Link>
      </div>
    </header>
  );
};
