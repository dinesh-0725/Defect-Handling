package com.steelplant.servlets;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletResponse;

import com.steelplant.db.OracleDBConnection;
// Plain text password storage

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String userType = request.getParameter("userType");
        
        try {
            Connection conn = OracleDBConnection.getConnection();
            
            // First check if username or email already exists
            String checkSql = "SELECT COUNT(*) FROM users WHERE username = ? OR email = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setString(1, username);
            checkStmt.setString(2, email);
            
            if (checkStmt.executeQuery().next()) {
                response.setContentType("application/json");
                response.getWriter().write("{\"success\":false,\"message\":\"Username or email already exists\"}");
                return;
            }
            
            // Store plain text password
            // Insert new user
            String insertSql = "INSERT INTO users (username, password, email, user_type, first_name, last_name, phone, address) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement pstmt = conn.prepareStatement(insertSql)) {
                pstmt.setString(1, username);
                pstmt.setString(2, password);
                pstmt.setString(3, email);
                pstmt.setString(4, userType);
                pstmt.setString(5, firstName);
                pstmt.setString(6, lastName);
                pstmt.setString(7, phone);
                pstmt.setString(8, address);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":true,\"message\":\"Registration successful\"}");
                } else {
                    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":false,\"message\":\"Registration failed\"}");
                }
            
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\":false,\"message\":\"An error occurred\"}");
        }
    }
}
