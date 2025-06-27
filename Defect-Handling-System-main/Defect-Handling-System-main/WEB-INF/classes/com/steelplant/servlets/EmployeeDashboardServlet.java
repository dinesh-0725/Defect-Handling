package com.steelplant.servlets;

import com.steelplant.db.OracleDBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class EmployeeDashboardServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("../login.jsp");
            return;
        }
        int userId = (int) session.getAttribute("user_id");
        List<Map<String, Object>> complaints = new ArrayList<>();
        try (Connection conn = OracleDBConnection.getConnection()) {
            String sql = "SELECT c.*, t.first_name as tech_first_name, t.last_name as tech_last_name, t.email as tech_email " +
                         "FROM complaints c " +
                         "LEFT JOIN users t ON c.assigned_to = t.user_id " +
                         "WHERE c.user_id = ? ORDER BY c.created_at DESC";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, userId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> complaint = new HashMap<>();
                        complaint.put("complaint_id", rs.getInt("complaint_id"));
                        complaint.put("title", rs.getString("title"));
                        complaint.put("description", rs.getString("description"));
                        complaint.put("location", rs.getString("location"));
                        complaint.put("status", rs.getString("status"));
                        complaint.put("image_path", rs.getString("image_path"));
                        complaint.put("created_at", rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toString() : "");
                        complaint.put("completion_image_path", rs.getString("completion_image_path"));
                        complaint.put("completion_notes", rs.getString("completion_notes"));
                        complaint.put("completion_date", rs.getTimestamp("completion_date") != null ? rs.getTimestamp("completion_date").toString() : "");
                        complaint.put("tech_first_name", rs.getString("tech_first_name"));
                        complaint.put("tech_last_name", rs.getString("tech_last_name"));
                        complaint.put("tech_email", rs.getString("tech_email"));
                        complaints.add(complaint);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        request.setAttribute("complaints", complaints);
        request.getRequestDispatcher("/employee/dashboard.jsp").forward(request, response);
    }
}
