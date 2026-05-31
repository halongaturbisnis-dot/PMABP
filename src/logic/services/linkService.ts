/**
 * Service to handle external links and navigation
 * Ensures PWA compatibility and consistent behavior across platforms
 */
export const linkService = {
  /**
   * Opens a URL in a new browser tab/window
   * @param url The target URL
   */
  openExternal: (url: string) => {
    if (!url) return;

    // Best practice for bypassing popup blockers and ensuring PWA compatibility
    const a = document.createElement('a');
    a.href = url;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    
    // Some browsers require the element to be in the DOM to trigger click
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  },

  /**
   * Specifically for opening files or images
   */
  openMedia: (url: string) => {
    linkService.openExternal(url);
  }
};
