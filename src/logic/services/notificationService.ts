import toast from 'react-hot-toast';
import Swal from 'sweetalert2';

/**
 * NOTIFICATION SERVICE
 * Standardized notification engine following NotificationRule.md
 */

export const notify = {
  // 1. CRUD & Operational (Toast)
  success: (message: string) => {
    toast.success(message, {
      duration: 3000,
      position: 'top-right',
    });
  },
  
  error: (message: string) => {
    toast.error(message, {
      duration: 4000,
      position: 'top-right',
    });
  },

  info: (message: string) => {
    toast(message, {
      duration: 3000,
      position: 'top-right',
      icon: 'ℹ️',
    });
  },

  // 2. Warning & Crucial (SWAL)
  async alert(title: string, text: string, icon: 'warning' | 'error' | 'success' | 'info' = 'info') {
    return Swal.fire({
      title,
      text,
      icon,
      confirmButtonText: 'OK',
      confirmButtonColor: '#3085d6',
    });
  },

  async confirm(title: string, text: string) {
    const result = await Swal.fire({
      title,
      text,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Ya, Lanjutkan!',
      cancelButtonText: 'Batal'
    });
    return result.isConfirmed;
  }
};
