import React from 'react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router-dom';
import { useGlobalState } from '../logic/context/GlobalContext';
import { APP_CONFIG } from '../logic/constants/app';
import { getDefaultRoute } from '../logic/utils/auth';
import { ArrowRight, Sparkles } from 'lucide-react';
import { cn } from '../logic/utils/cn';
import { appAssets } from '../ui/styles/assets';

/**
 * WELCOMING PAGE (Seamless & Animated BG)
 * Background putih bersih dengan animasi grid gradasi halus.
 */
const WelcomingPage: React.FC = () => {
  const { state } = useGlobalState();
  const navigate = useNavigate();
  const user = state.user;

  const handleContinue = () => {
    const targetPath = getDefaultRoute(user);
    const finalPath = targetPath === '/' ? '/dashboard' : targetPath;
    navigate(finalPath);
  };

  if (!user) return null;

  return (
    // Container Background Utama: Putih Mutlak
    <div className="min-h-[100dvh] w-full flex flex-col items-center justify-center relative bg-[#ffffff] overflow-hidden">
      
      {/* --- ANIMATED BACKGROUND ELEMENTS --- */}
      
      {/* 1. Moving Grid Pattern (Background Tekstur Modern) */}
      <div className="absolute inset-0 z-0 opacity-[0.03] pointer-events-none" 
           style={{
             backgroundImage: `linear-gradient(#013d13 1px, transparent 1px), linear-gradient(90deg, #013d13 1px, transparent 1px)`,
             backgroundSize: '40px 40px',
           }} 
      />


      {/* --- MAIN CONTENT (SEAMLESS / NO CARD) --- */}
      <div className="relative z-10 w-full max-w-[32rem] px-6 flex flex-col items-center text-center">
        
        {/* Profile Image Wrapper */}
        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.9 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="mb-8 relative"
        >
          {/* Foto Profil dengan Border Elegan */}
          <div className="w-28 h-28 md:w-36 md:h-36 rounded-full p-1 bg-gradient-to-b from-[#013d13] to-[#4ade80] shadow-[0_8px_30px_rgba(1,61,19,0.15)]">
            <div className="w-full h-full rounded-full p-[3px] bg-white">
              <img 
                src={user.foto_profil || appAssets.AccountPlaceholder} 
                alt={user.username} 
                className="w-full h-full rounded-full object-cover"
              />
            </div>
          </div>
          
          {/* Status Dot */}
          <div className="absolute bottom-2 right-2 w-6 h-6 bg-[#013d13] border-4 border-[#ffffff] rounded-full shadow-sm" />
        </motion.div>

        {/* Text Content */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
          className="space-y-4 mb-10"
        >

          <h1 className="text-3xl md:text-4xl font-semibold text-slate-900 tracking-tight leading-[1.2]">
            Selamat Datang, <br />
            <span className="text-[#013d13] font-bold">{user.username}</span>
          </h1>
          
          <p className="text-Black text-base md:text-lg leading-none max-w-[26rem] mx-auto font-light">
            di Portal Bisnis <span className="font-semibold text-black">{appAssets.Company}</span>
          </p>
          <p className="text-sblack text-base md:text-lg leading-none max-w-[26rem] mx-auto font-light">
            Semoga pekerjaanmu lancar hari ini
          </p>
        </motion.div>

        {/* Action Button */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
          className="w-full"
        >
        </motion.div>
      </div>
      
      {/* Footer */}
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.5 }}
        transition={{ delay: 0.6, duration: 1 }}
        className="absolute bottom-8 text-Black text-xs font-bold tracking-widest uppercase z-10"
      >
        {APP_CONFIG.name}
      </motion.div>
    </div>
  );
};

export default WelcomingPage;