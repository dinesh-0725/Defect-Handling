package com.steelplant.db;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.SQLException;
import com.steelplant.config.DatabaseConfig;

public class DatabaseInitializer {
    public static void createTables() {
        try {
            // Get database connection
            Connection conn = OracleDBConnection.getConnection();
            Statement stmt = conn.createStatement();
            
            // Read and execute schema SQL file
            // Corrected path to schema.sql, relative to the project root directory
            BufferedReader reader = new BufferedReader(new FileReader("sql/schema.sql"));
            StringBuilder sql = new StringBuilder();
            String line;
            
            StringBuilder currentStatementBuffer = new StringBuilder();
            // String line; // Removed duplicate declaration

            while ((line = reader.readLine()) != null) {
                String trimmedLine = line.trim();

                if (trimmedLine.isEmpty() || trimmedLine.startsWith("--")) {
                    continue; // Skip empty lines and comments
                }

                currentStatementBuffer.append(trimmedLine).append(" "); // Append line and a space

                if (trimmedLine.endsWith(";")) {
                    String queryToExecute = currentStatementBuffer.toString().trim();
                    // Remove trailing semicolon if present before execution
                    if (queryToExecute.endsWith(";")) {
                        queryToExecute = queryToExecute.substring(0, queryToExecute.length() - 1);
                    }

                    if (!queryToExecute.isEmpty()) {
                        try {
                            stmt.execute(queryToExecute);
                            System.out.println("Executed: " + queryToExecute);
                        } catch (SQLException e) {
                            System.err.println("Error executing: [" + queryToExecute + "]");
                            System.err.println("SQLState: " + e.getSQLState() + ", ErrorCode: " + e.getErrorCode());
                            System.err.println("Message: " + e.getMessage());
                            // e.printStackTrace(); // Optionally print full stack trace for deeper debug
                        }
                        currentStatementBuffer.setLength(0); // Reset for the next statement
                    }
                }
            }
            reader.close();

            // Execute any remaining statement in the buffer (if the file doesn't end with a semicolon and newline)
            String remainingQuery = currentStatementBuffer.toString().trim();
            // Remove trailing semicolon if present for the remaining query
            if (remainingQuery.endsWith(";")) {
                remainingQuery = remainingQuery.substring(0, remainingQuery.length() - 1);
            }
            if (!remainingQuery.isEmpty()) {
                try {
                    stmt.execute(remainingQuery);
                    System.out.println("Executed (remaining): " + remainingQuery);
                } catch (SQLException e) {
                    System.err.println("Error executing (remaining): [" + remainingQuery + "]");
                    System.err.println("SQLState: " + e.getSQLState() + ", ErrorCode: " + e.getErrorCode());
                    System.err.println("Message: " + e.getMessage());
                }
            }
            
            stmt.close();
            if (conn != null) {
                OracleDBConnection.closeConnection(conn);
            }
            
            System.out.println("Database tables created successfully!");
            
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error creating database tables: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        createTables();
    }
}
