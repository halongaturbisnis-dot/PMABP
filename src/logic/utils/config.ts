/**
 * Environment Configuration Validator
 */

export const config = {
  geminiApiKey: typeof process !== 'undefined' ? process.env.GEMINI_API_KEY : '',
  groqApiKey: typeof process !== 'undefined' ? process.env.GROQ_API_KEY : '',
  appUrl: (import.meta as any).env?.VITE_APP_URL || (typeof process !== 'undefined' ? process.env.VITE_APP_URL : ''),
  
  tigris: {
    bucket: (import.meta as any).env?.VITE_TIGRIS_STORAGE_BUCKET || (typeof process !== 'undefined' ? process.env.VITE_TIGRIS_STORAGE_BUCKET : ''),
    endpoint: (import.meta as any).env?.VITE_TIGRIS_STORAGE_ENDPOINT || (typeof process !== 'undefined' ? process.env.VITE_TIGRIS_STORAGE_ENDPOINT : ''),
    accessKeyId: (import.meta as any).env?.VITE_TIGRIS_STORAGE_ACCESS_KEY_ID || (typeof process !== 'undefined' ? process.env.VITE_TIGRIS_STORAGE_ACCESS_KEY_ID : ''),
    secretAccessKey: (import.meta as any).env?.VITE_TIGRIS_STORAGE_SECRET_ACCESS_KEY || (typeof process !== 'undefined' ? process.env.VITE_TIGRIS_STORAGE_SECRET_ACCESS_KEY : ''),
  },

  turso: {
    url: (import.meta as any).env?.VITE_TURSO_DB_URL || (typeof process !== 'undefined' ? process.env.VITE_TURSO_DB_URL : ''),
    authToken: (import.meta as any).env?.VITE_TURSO_DB_AUTH_TOKEN || (typeof process !== 'undefined' ? process.env.VITE_TURSO_DB_AUTH_TOKEN : ''),
  },
  
  validate: () => {
    const isServer = typeof process !== 'undefined';
    
    // Server-only validation
    if (isServer) {
      const serverRequired = ['GEMINI_API_KEY'];
      serverRequired.forEach(key => {
        if (!process.env[key]) {
          console.warn(`[Config Warning]: Missing server-side environment variable ${key}`);
        }
      });
    }

    // Shared/Client validation (prefixed with VITE_)
    if (!config.turso.url) console.warn('[Config Warning]: VITE_TURSO_DB_URL is missing');
    if (!config.tigris.endpoint) console.warn('[Config Warning]: VITE_TIGRIS_STORAGE_ENDPOINT is missing');
    if (!config.appUrl) console.warn('[Config Warning]: VITE_APP_URL is missing');
  }
};
