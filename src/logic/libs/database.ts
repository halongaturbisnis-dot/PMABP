/**
 * Database client bridge
 * Acts as a centralized logic layer for database interactions.
 */

import { tursoRequest } from '../api/turso.js';

export const dbClient = {
  /**
   * Executes a raw SQL query using the Turso (LibSQL) client.
   * @param sql The SQL statement to execute.
   * @param args Optional arguments for the query.
   */
  query: async (sql: string, args: any[] = []) => {
    try {
      const result = await tursoRequest(sql, args);
      return result;
    } catch (error) {
      console.error('Database Client Error:', error);
      throw error;
    }
  }
};
