package com.steelplant.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import com.google.gson.Gson;
import com.steelplant.db.OracleDBConnection;

public class UserManagementServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_type") == null || !session.getAttribute("user_type").equals("ADMIN")) {
            response.sendRedirect("../login.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("listUsers".equals(action)) {
            // Logic to list users - to be implemented
            // For now, could forward to manage_users.jsp or send JSON
            response.getWriter().println("User listing via servlet - to be implemented.");
        } else {
            // Handle other GET actions or show an error/default page
            response.getWriter().println("Unknown action for UserManagementServlet GET request.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) { // Any authenticated user can change their own password
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "You are not authorized to perform this action.");
            return;
        }

        String action = request.getParameter("action");

        if ("changePassword".equals(action)) {
            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            Integer userId = (Integer) session.getAttribute("user_id");

            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            Gson gson = new Gson();
            Map<String, Object> jsonResponse = new HashMap<>();

            if (userId == null) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Session expired or invalid. Please log in again.");
                out.print(gson.toJson(jsonResponse));
                out.flush();
                return;
            }

            try (Connection conn = OracleDBConnection.getConnection()) {
                // Get current hashed password
                String sqlSelect = "SELECT password FROM users WHERE user_id = ?";
                String storedHash = null;
                try (PreparedStatement pstmtSelect = conn.prepareStatement(sqlSelect)) {
                    pstmtSelect.setInt(1, userId);
                    try (ResultSet rs = pstmtSelect.executeQuery()) {
                        if (rs.next()) {
                            storedHash = rs.getString("password");
                        } else {
                            jsonResponse.put("success", false);
                            jsonResponse.put("message", "User not found.");
                            out.print(gson.toJson(jsonResponse));
                            out.flush();
                            return;
                        }
                    }
                }

                // Verify current password (plain text comparison)
                if (storedHash == null || !storedHash.equals(currentPassword)) {
                    jsonResponse.put("success", false);
                    jsonResponse.put("message", "Incorrect current password.");
                    out.print(gson.toJson(jsonResponse));
                    out.flush();
                    return;
                }

                // Update with new password (plain text)
                String sqlUpdate = "UPDATE users SET password = ? WHERE user_id = ?";
                try (PreparedStatement pstmtUpdate = conn.prepareStatement(sqlUpdate)) {
                    pstmtUpdate.setString(1, newPassword);
                    pstmtUpdate.setInt(2, userId);
                    int rowsAffected = pstmtUpdate.executeUpdate();
                    if (rowsAffected > 0) {
                        jsonResponse.put("success", true);
                        jsonResponse.put("message", "Password changed successfully.");
                    } else {
                        jsonResponse.put("success", false);
                        jsonResponse.put("message", "Failed to update password. Please try again.");
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Database error: " + e.getMessage());
            } catch (Exception e) {
                e.printStackTrace();
                jsonResponse.put("success", false);
                jsonResponse.put("message", "An unexpected error occurred: " + e.getMessage());
            }
            out.print(gson.toJson(jsonResponse));
            out.flush();
        } else if ("updateUser".equals(action)) {
            // Logic to update user details - to be implemented
            response.getWriter().println("User update via servlet - to be implemented.");
        } else {
            // Handle other POST actions or show an error
            response.getWriter().println("Unknown action for UserManagementServlet POST request.");
        }
    }
}
