/**
 * SERVICES/DATABASEACTIVESERVICE.TS
 * Service to handle database keep-alive (ping) logic.
 */

import { dbClient } from '../libs/database';

export const databaseActiveService = {
  /**
   * Performs a ping to the database by inserting a record into PingMonitoring.
   * @param triggeredBy The source of the trigger ('CRON', 'SYSTEM', 'MANUAL')
   */
  async ping(triggeredBy: string = 'CRON'): Promise<{ success: boolean; message: string }> {
    const sql = `
      INSERT INTO PingMonitoring (id, status, message, triggered_by, ping_at)
      VALUES ('singleton-ping-monitor', ?, ?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(id) DO UPDATE SET
        status = excluded.status,
        message = excluded.message,
        triggered_by = excluded.triggered_by,
        ping_at = excluded.ping_at
    `;
    
    try {
      await dbClient.query(sql, ['SUCCESS', 'Database is active', triggeredBy]);
      console.log(`[${new Date().toISOString()}] Database Ping Successful triggered by ${triggeredBy}`);
      return { success: true, message: 'Ping successful' };
    } catch (error: any) {
      const errorMessage = error?.message || 'Unknown error occurred during ping';
      console.error(`[${new Date().toISOString()}] Database Ping Failed:`, errorMessage);
      
      // Fallback: log the failure if possible, or just return result
      try {
        // Attempt to log failure to DB (might fail if DB is down)
        await dbClient.query(sql, ['FAILED', errorMessage, triggeredBy]);
      } catch (innerError) {
        // Silent fail if DB is completely unreachable
      }
      
      return { success: false, message: errorMessage };
    }
  },

  /**
   * Gets the last successful ping time from the database.
   */
  async getLastPing() {
    const sql = `SELECT * FROM PingMonitoring WHERE status = 'SUCCESS' ORDER BY ping_at DESC LIMIT 1`;
    try {
      const result = await dbClient.query(sql);
      return result;
    } catch (error) {
      console.error('Failed to fetch last ping:', error);
      return null;
    }
  }
};
