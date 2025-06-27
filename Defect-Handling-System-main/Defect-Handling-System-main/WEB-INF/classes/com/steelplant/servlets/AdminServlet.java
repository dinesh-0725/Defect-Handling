package com.steelplant.servlets;

import com.google.gson.Gson;
import com.steelplant.db.OracleDBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/AdminServlet")
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            response.setContentType("application/json");
            response.getWriter().write("{\"success\":false,\"message\":\"No action specified\"}");
            return;
        }

        try {
            switch (action) {
                case "getTechnicians":
                    handleGetTechnicians(request, response);
                    break;
                case "getPendingComplaints":
                    handleGetPendingComplaints(request, response);
                    break;
                default:
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":false,\"message\":\"Invalid action\"}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }

    private void handleGetTechnicians(HttpServletRequest request, HttpServletResponse response) 
            throws IOException, SQLException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            String sql = "SELECT user_id, first_name, last_name, specialization FROM users WHERE user_type = 'TECHNICIAN' AND status = 'ACTIVE'";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                ResultSet rs = pstmt.executeQuery();
                
                List<Map<String, String>> technicians = new ArrayList<>();
                while (rs.next()) {
                    Map<String, String> tech = new HashMap<>();
                    tech.put("user_id", rs.getString("user_id"));
                    tech.put("first_name", rs.getString("first_name"));
                    tech.put("last_name", rs.getString("last_name"));
                    tech.put("specialization", rs.getString("specialization"));
                    technicians.add(tech);
                }
                
                result.put("success", true);
                result.put("technicians", technicians);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error retrieving technicians: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }

    private void handleGetPendingComplaints(HttpServletRequest request, HttpServletResponse response) 
            throws IOException, SQLException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            String sql = "SELECT c.*, u.first_name, u.last_name, u.email, u.phone_number, u.department, u.designation, u.role, u.specialization, u.user_type " +
                       "FROM complaints c " +
                       "JOIN users u ON c.user_id = u.user_id " +
                       "WHERE c.status = 'PENDING' ORDER BY c.created_at DESC";
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                try (ResultSet rs = pstmt.executeQuery()) {
                    List<Map<String, Object>> complaints = new ArrayList<>();
                    
                    while (rs.next()) {
                        Map<String, Object> complaint = new HashMap<>();
                        complaint.put("complaint_id", rs.getInt("complaint_id"));
                        complaint.put("user_id", rs.getInt("user_id"));
                        complaint.put("title", rs.getString("title"));
                        complaint.put("description", rs.getString("description"));
                        complaint.put("location", rs.getString("location"));
                        complaint.put("status", rs.getString("status"));
                        complaint.put("image_path", rs.getString("image_path"));
                        complaint.put("created_at", rs.getTimestamp("created_at").toString());
                        complaint.put("first_name", rs.getString("first_name"));
                        complaint.put("last_name", rs.getString("last_name"));
                        complaint.put("email", rs.getString("email"));
                        complaint.put("phone_number", rs.getString("phone_number"));
                        complaint.put("department", rs.getString("department"));
                        complaint.put("designation", rs.getString("designation"));
                        complaint.put("role", rs.getString("role"));
                        complaint.put("specialization", rs.getString("specialization"));
                        complaint.put("user_type", rs.getString("user_type"));
                        
                        complaints.add(complaint);
                    }
                    
                    result.put("success", true);
                    result.put("complaints", complaints);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error retrieving pending complaints: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
}
