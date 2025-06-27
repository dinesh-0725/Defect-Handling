package com.steelplant.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import com.steelplant.config.DatabaseConfig;

public class OracleDBConnection {
    private static final Logger logger = Logger.getLogger(OracleDBConnection.class.getName());
    
    // Initialize the driver when the class is loaded
    static {
        try {
            // Set login timeout
            DriverManager.setLoginTimeout(DatabaseConfig.CONNECTION_TIMEOUT);
            // Load the Oracle JDBC driver
            Class.forName(DatabaseConfig.DB_DRIVER);
            logger.info("\u2705 Oracle JDBC Driver loaded successfully");
        } catch (ClassNotFoundException e) {
            String errorMsg = "\u274C Failed to load Oracle JDBC Driver: " + e.getMessage();
            logger.log(Level.SEVERE, errorMsg, e);
            throw new ExceptionInInitializerError(errorMsg);
        } catch (Exception e) {
            String errorMsg = "\u274C Error initializing database connection: " + e.getMessage();
            logger.log(Level.SEVERE, errorMsg, e);
            throw new ExceptionInInitializerError(errorMsg);
        }
    }

    /**
     * Gets a database connection with proper configuration and validation.
     * @return A new database connection
     * @throws SQLException if a database access error occurs or connection fails
     */
    public static Connection getConnection() throws SQLException {
        Connection conn = null;
        long startTime = System.currentTimeMillis();
        
        try {
            // Set connection properties
            Properties props = new Properties();
            props.setProperty("user", DatabaseConfig.DB_USERNAME);
            props.setProperty("password", DatabaseConfig.DB_PASSWORD);
            
            // For SYS user
            if (DatabaseConfig.DB_USERNAME.toUpperCase().contains("SYS")) {
                props.setProperty("internal_logon", "sysdba");
            }
            
            // Important connection properties
            props.setProperty("oracle.jdbc.autoCommitSpecCompliant", "false");
            props.setProperty("oracle.net.CONNECT_TIMEOUT", 
                String.valueOf(DatabaseConfig.CONNECTION_TIMEOUT * 1000));
            props.setProperty("oracle.jdbc.ReadTimeout", 
                String.valueOf(DatabaseConfig.SOCKET_TIMEOUT * 1000));
            props.setProperty("oracle.net.READ_TIMEOUT", 
                String.valueOf(DatabaseConfig.SOCKET_TIMEOUT * 1000));
            props.setProperty("oracle.jdbc.TcpNoDelay", "true");
            
            logger.info("\uD83D\uDD0D Attempting to connect to: " + DatabaseConfig.DB_URL);
            
            // Get connection
            conn = DriverManager.getConnection(DatabaseConfig.DB_URL, props);
            
            // Validate connection
            if (conn == null || conn.isClosed()) {
                throw new SQLException("Connection is null or closed immediately after creation");
            }
            
            // Configure connection
            conn.setAutoCommit(false);
            
            // Test the connection
            try (var stmt = conn.createStatement()) {
                stmt.setQueryTimeout(5);
                stmt.execute(DatabaseConfig.VALIDATION_QUERY);
            }
            
            long duration = System.currentTimeMillis() - startTime;
            logger.info(String.format("✅ Database connection established successfully in %d ms", duration));
            
            return conn;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Failed to create database connection", e);
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException ex) {
                    logger.log(Level.SEVERE, "Error closing connection after failure", ex);
                }
            }
            throw new SQLException("Failed to connect to the database: " + e.getMessage(), e);
        }
    }

    /**
     * Safely closes a database connection with proper error handling.
     * Rolls back any pending transactions before closing the connection.
     * 
     * @param conn The database connection to close (can be null)
     */
    public static void closeConnection(Connection conn) {
        if (conn == null) {
            return;
        }
        
        try {
            if (conn.isClosed()) {
                logger.fine("Connection is already closed");
                return;
            }
            
            // Only rollback if not in auto-commit mode and connection is still valid
            if (!conn.getAutoCommit()) {
                try {
                    if (!conn.isValid(5)) { // 5 second timeout
                        logger.warning("Connection is not valid, skipping rollback");
                    } else {
                        logger.fine("Rolling back any pending transactions");
                        conn.rollback();
                    }
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error during rollback: " + e.getMessage(), e);
                }
            }
            
            // Close the connection
            logger.fine("Closing database connection");
            conn.close();
            logger.info("✅ Database connection closed successfully");
            
        } catch (SQLException e) {
            String errorMsg = "\u274C Error closing database connection: " + e.getMessage();
            if (e.getErrorCode() != 0) {
                errorMsg += " (Error Code: " + e.getErrorCode() + ")";
            }
            logger.log(Level.SEVERE, errorMsg, e);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error while closing connection: " + e.getMessage(), e);
        }
    }

    /**
     * Safely closes multiple resources in the correct order.
     * Can handle any AutoCloseable resources (Connection, Statement, ResultSet, etc.)
     * 
     * @param resources The resources to close (can be null or contain nulls)
     */
    public static void closeResources(AutoCloseable... resources) {
        for (AutoCloseable resource : resources) {
            if (resource != null) {
                try {
                    resource.close();
                } catch (Exception e) {
                    logger.log(Level.WARNING, "Error closing resource: " + e.getMessage(), e);
                }
            }
        }
    }
    
    /**
     * Tests the database connection and returns detailed diagnostic information.
     * @return true if the connection test was successful, false otherwise
     */
    public static boolean testConnection() {
        Connection conn = null;
        try {
            logger.info("\uD83D\uDD0D Starting database connection test...");
            
            // Get a new connection
            conn = getConnection();
            if (conn == null) {
                logger.severe("\u274C Connection is null after getConnection()");
                return false;
            }
            
            if (conn.isClosed()) {
                logger.severe("\u274C Connection is closed after getConnection()");
                return false;
            }
            
            // Test connection with a simple query
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT 'TEST' AS test FROM DUAL")) {
                
                if (!rs.next()) {
                    logger.severe("\u274C Test query returned no results");
                    return false;
                }
                
                String result = rs.getString(1);
                if (!"TEST".equals(result)) {
                    logger.severe("\u274C Test query returned unexpected result: " + result);
                    return false;
                }
                
                // Get database metadata
                java.sql.DatabaseMetaData meta = conn.getMetaData();
                logger.info("✅ Connection test successful");
                logger.info("   Database: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion());
                logger.info("   Driver: " + meta.getDriverName() + " " + meta.getDriverVersion());
                logger.info("   URL: " + meta.getURL());
                logger.info("   User: " + meta.getUserName());
                
                return true;
            }
            
        } catch (SQLException e) {
            String errorMsg = "\u274C Connection test failed: " + e.getMessage();
            if (e.getErrorCode() != 0) {
                errorMsg += " (Error Code: " + e.getErrorCode() + ")";
            }
            logger.log(Level.SEVERE, errorMsg, e);
            return false;
        } finally {
            // Make sure to close the connection
            closeConnection(conn);
        }
    }
}
