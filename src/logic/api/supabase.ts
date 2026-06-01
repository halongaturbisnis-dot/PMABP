import { createClient, SupabaseClient } from '@supabase/supabase-js';

/**
 * API/SUPABASE.TS
 * Supabase client initialization with Lazy Initialization.
 */

let supabaseInstance: SupabaseClient | null = null;

export const getSupabase = (): SupabaseClient => {
  if (supabaseInstance) return supabaseInstance;

  // @ts-ignore
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
  // @ts-ignore
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  if (!supabaseUrl || !supabaseAnonKey) {
    console.warn("[Supabase Warning]: Supabase URL or Anon Key is missing.");
  }

  supabaseInstance = createClient(supabaseUrl, supabaseAnonKey);
  return supabaseInstance;
};
