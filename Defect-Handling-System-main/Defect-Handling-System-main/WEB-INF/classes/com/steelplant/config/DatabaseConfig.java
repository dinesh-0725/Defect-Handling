package com.steelplant.config;

/**
 * Database configuration settings for Oracle Database connection.
 * Uses the Oracle Thin JDBC driver for database connectivity.
 */
public class DatabaseConfig {
    // Oracle JDBC driver class name
    public static final String DB_DRIVER = "oracle.jdbc.driver.OracleDriver";
    
    // Database connection URL
    // Format: jdbc:oracle:thin:@//hostname:port/service_name
    // JDBC URL - Using EZCONNECT syntax with service name
    // Using the database service name 'orcl' from the database
    public static final String DB_URL = "jdbc:oracle:thin:@//localhost:1521/orcl";
    
    // Alternative format using SID (if needed): jdbc:oracle:thin:@localhost:1521:ORCL
    
    // Database credentials
    public static final String DB_USERNAME = "SYS";
    public static final String DB_PASSWORD = "12345";
    
    // Connection properties (used in OracleDBConnection)
    public static final int CONNECTION_TIMEOUT = 10; // seconds
    public static final int SOCKET_TIMEOUT = 30; // seconds
    
    // Validation query - simple query to test the connection
    public static final String VALIDATION_QUERY = "SELECT 1 FROM DUAL";
}
