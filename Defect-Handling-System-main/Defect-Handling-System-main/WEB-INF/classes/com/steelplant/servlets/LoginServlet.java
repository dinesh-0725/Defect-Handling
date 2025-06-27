package com.steelplant.servlets;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import com.steelplant.db.OracleDBConnection;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger logger = Logger.getLogger(LoginServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        logger.info("Login attempt started");
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        
        logger.log(Level.INFO, "Login attempt for user: {0}", username);
        
        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            logger.warning("Empty username or password provided");
            sendJsonResponse(response, false, "Username and password are required.");
            return;
        }
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            // Get database connection
            logger.info("Attempting to get database connection...");
            conn = OracleDBConnection.getConnection();
            logger.info("Database connection established successfully");
            
            // Prepare and execute query
            String sql = "SELECT user_id, username, password, user_type FROM users WHERE username = ?";
            logger.info("Executing query: " + sql + " with username: " + username);
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            
            if (rs.next()) { // Username found
                String storedPassword = rs.getString("password");
                int userId = rs.getInt("user_id");
                String userType = rs.getString("user_type");
                
                logger.info(String.format("User found - ID: %d, Type: %s PASS: %s", userId, userType, storedPassword));
                
                // Compare plain text passwords
                if (storedPassword != null && storedPassword.equals(password)) {
                    logger.info("Password matches for user: " + username);
                    
                    // Set session attributes
                    HttpSession session = request.getSession();
                    session.setAttribute("user_id", userId);
                    session.setAttribute("username", username);
                    session.setAttribute("user_type", userType);
                    
                    // Determine redirect URL based on user type
                    String redirectUrl = getRedirectUrl(userType);
                    if (redirectUrl == null) {
                        logger.warning("Invalid user type: " + userType);
                        sendJsonResponse(response, false, "Invalid user type configured for your account.");
                        return;
                    }
                    
                    logger.info("Login successful, redirecting to: " + redirectUrl);
                    sendJsonResponse(response, true, redirectUrl);
                } else {
                    logger.warning("Password does not match for user: " + username);
                    sendJsonResponse(response, false, "Invalid username or password.");
                }
            } else {
                logger.warning("No user found with username: " + username);
                sendJsonResponse(response, false, "Invalid username or password.");
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error during login", e);
            sendJsonResponse(response, false, "An error occurred during login. Please try again.");
        } finally {
            // Close resources
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
    
    private void sendJsonResponse(HttpServletResponse response, boolean success, String message) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.format("{\"success\":%b,\"message\":\"%s\"}", 
            success, message.replace("\"", "\\\"")));
    }
    
    private String getRedirectUrl(String userType) {
        if (userType == null) return null;
        
        switch (userType.toUpperCase()) {
            case "ADMIN":
                return "admin/dashboard.jsp";
            case "EMPLOYEE":
                return "employee/dashboard.jsp";
            case "TECHNICIAN":
                return "technician/dashboard.jsp";
            default:
                return null;
        }
    }
}
