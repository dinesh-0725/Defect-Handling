package com.steelplant.servlets;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.PrintWriter;
import com.google.gson.Gson;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import jakarta.servlet.http.HttpSession;

import com.steelplant.db.OracleDBConnection;

@WebServlet("/ComplaintServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024 * 2, // 2MB
        maxFileSize = 1024 * 1024 * 10,      // 10MB
        maxRequestSize = 1024 * 1024 * 50)   // 50MB
public class ComplaintServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            // Handle new complaint registration
            handleNewComplaint(request, response);
        } else {
            // Handle other actions
            switch (action) {
                case "assign":
                    handleAssignComplaint(request, response);
                    break;
                case "update":
                    handleUpdateComplaint(request, response);
                    break;
                default:
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":false,\"message\":\"Invalid action\"}");
            }
        }
    }

    private void handleGetComplaints(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            String userId = request.getParameter("userId");
            if (userId == null || userId.isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                result.put("success", false);
                result.put("message", "User ID is required");
                out.print(gson.toJson(result));
                return;
            }
            
            String sql = "SELECT c.*, u.username, u.first_name, u.last_name, u.email, u.phone_number, u.department, u.designation, u.role, u.specialization " +
                       "FROM complaints c " +
                       "JOIN users u ON c.user_id = u.user_id " +
                       "WHERE c.user_id = ? " +
                       "ORDER BY c.created_at DESC";
                        
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, Integer.parseInt(userId));
                try (ResultSet rs = stmt.executeQuery()) {
                    List<Map<String, Object>> complaints = new ArrayList<>();
                    while (rs.next()) {
                        Map<String, Object> complaint = new HashMap<>();
                        complaint.put("id", rs.getInt("complaint_id"));
                        complaint.put("title", rs.getString("title"));
                        complaint.put("description", rs.getString("description"));
                        complaint.put("location", rs.getString("location"));
                        complaint.put("status", rs.getString("status"));
                        complaint.put("image_path", rs.getString("image_path"));
                        complaint.put("created_at", rs.getTimestamp("created_at").toString());
                        complaint.put("user_id", rs.getInt("user_id"));
                        complaints.add(complaint);
                    }
                    
                    result.put("success", true);
                    result.put("complaints", complaints);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            result.put("success", false);
            result.put("message", "Error fetching complaints: " + e.getMessage());
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            result.put("success", false);
            result.put("message", "Invalid user ID format");
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            // Handle get complaints for regular users
            handleGetComplaints(request, response);
        } else {
            switch (action) {
                case "view":
                    handleViewComplaint(request, response);
                    break;
                case "getTechnicians":
                    handleGetTechnicians(request, response);
                    break;
                case "getPendingComplaints":
                    handleGetPendingComplaints(request, response);
                    break;
                case "getAssignedComplaints":
                    handleGetAssignedComplaints(request, response);
                    break;
                case "getEmployeeComplaints":
                    handleGetEmployeeComplaints(request, response);
                    break;
                default:
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":false,\"message\":\"Invalid action\"}");
            }
        }
    }

    private void handleGetTechnicians(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            // Query to get all technicians with their details
            String sql = "SELECT user_id, username, email, first_name, last_name FROM users WHERE user_type = 'TECHNICIAN'";
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                List<Map<String, Object>> technicians = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> tech = new HashMap<>();
                    tech.put("id", rs.getInt("user_id"));
                    // Build display name with fallback to username
                    String firstName = rs.getString("first_name");
                    String lastName = rs.getString("last_name");
                    String displayName = rs.getString("username"); // Default to username
                    
                    // If we have both first and last name, use them
                    if (firstName != null && !firstName.trim().isEmpty()) {
                        displayName = firstName.trim();
                        if (lastName != null && !lastName.trim().isEmpty()) {
                            displayName += " " + lastName.trim();
                        }
                    }
                    tech.put("name", displayName);
                    tech.put("email", rs.getString("email"));
                    technicians.add(tech);
                }
                
                result.put("success", true);
                result.put("technicians", technicians);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error fetching technicians: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private void handleGetPendingComplaints(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            String sql = "SELECT c.complaint_id, c.title, c.description, c.status, c.location, c.image_path, c.created_at, u.username as employee_name " +
                       "FROM complaints c " +
                       "JOIN users u ON c.user_id = u.user_id " +
                       "WHERE c.status = 'PENDING' ORDER BY c.created_at DESC";
                         
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                List<Map<String, Object>> complaints = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> complaint = new HashMap<>();
                    complaint.put("complaint_id", rs.getInt("complaint_id"));
                    complaint.put("title", rs.getString("title"));
                    complaint.put("description", rs.getString("description"));
                    complaint.put("status", rs.getString("status"));
                    complaint.put("location", rs.getString("location"));
                    complaint.put("createdAt", rs.getTimestamp("created_at").toString());
                    complaint.put("employeeName", rs.getString("employee_name"));
                    complaint.put("image_path", rs.getString("image_path"));
                    complaints.add(complaint);
                }
                
                result.put("success", true);
                result.put("complaints", complaints);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error fetching pending complaints: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private void handleNewComplaint(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            // Start transaction
            conn.setAutoCommit(false);
            
            try {
                // Get parameters
                String title = request.getParameter("title");
                String description = request.getParameter("description");
                String location = request.getParameter("location");
                int userId = Integer.parseInt(request.getParameter("userId"));
                
                // Handle file upload
                Part filePart = request.getPart("image");
                String fileName = null;
                String imagePath = null;
                
                if (filePart != null && filePart.getSize() > 0) {
                    fileName = filePart.getSubmittedFileName();
                    if (fileName != null && !fileName.isEmpty()) {
                        // Create uploads directory if it doesn't exist
                        String uploadPath = getServletContext().getRealPath("/uploads");
                        File uploadDir = new File(uploadPath);
                        if (!uploadDir.exists()) {
                            uploadDir.mkdirs();
                        }
                        
                        // Generate unique filename
                        String fileExtension = "";
                        int i = fileName.lastIndexOf('.');
                        if (i > 0) {
                            fileExtension = fileName.substring(i);
                        }
                        String uniqueFileName = "complaint_" + System.currentTimeMillis() + fileExtension;
                        imagePath = "uploads/" + uniqueFileName;
                        
                        // Save file
                        filePart.write(uploadPath + File.separator + uniqueFileName);
                    }
                }
                
                // Insert into database with current timestamp
                String sql = "INSERT INTO complaints (user_id, title, description, location, image_path, status, created_at) " +
                           "VALUES (?, ?, ?, ?, ?, 'PENDING', CURRENT_TIMESTAMP)";
                
                try (PreparedStatement pstmt = conn.prepareStatement(sql, new String[]{"complaint_id"})) {
                    pstmt.setInt(1, userId);
                    pstmt.setString(2, title);
                    pstmt.setString(3, description);
                    pstmt.setString(4, location);
                    pstmt.setString(5, imagePath);
                    
                    int affectedRows = pstmt.executeUpdate();
                    
                    if (affectedRows == 0) {
                        throw new SQLException("Creating complaint failed, no rows affected.");
                    }
                    
                    // Get the generated complaint ID
                    try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                        if (generatedKeys.next()) {
                            int complaintId = generatedKeys.getInt(1);
                            result.put("complaintId", complaintId);
                        } else {
                            throw new SQLException("Creating complaint failed, no ID obtained.");
                        }
                    }
                }
                
                // Commit transaction
                conn.commit();
                
                result.put("success", true);
                result.put("message", "Complaint registered successfully!");
                
            } catch (Exception e) {
                // Rollback transaction on error
                if (conn != null) {
                    try {
                        conn.rollback();
                    } catch (SQLException ex) {
                        ex.printStackTrace();
                    }
                }
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error registering complaint: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }

    private void handleGetComplaints(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try (Connection conn = OracleDBConnection.getConnection()) {
            String userId = request.getParameter("userId");
            
            String sql = "SELECT c.*, u.first_name, u.last_name, u.email, u.phone_number, u.department, u.designation, u.role, u.specialization, u.user_type " +
                       "FROM complaints c " +
                       "JOIN users u ON c.user_id = u.user_id " +
                       "WHERE c.user_id = ? ORDER BY c.created_at DESC";
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, Integer.parseInt(userId));
                
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
                    
                    response.setContentType("application/json");
                    response.getWriter().write(new Gson().toJson(Map.of("success", true, "complaints", complaints)));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\":false,\"message\":\"An error occurred\"}");
        }
    }

    private void handleAssignComplaint(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            int complaintId = Integer.parseInt(request.getParameter("complaintId"));
            int technicianId = Integer.parseInt(request.getParameter("technicianId"));
            
            String sql = "UPDATE complaints SET status = 'ASSIGNED', assigned_to = ? WHERE complaint_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, technicianId);
                pstmt.setInt(2, complaintId);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    result.put("success", true);
                    result.put("message", "Complaint assigned successfully");
                } else {
                    result.put("success", false);
                    result.put("message", "No complaint found with the given ID");
                }
            }
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid complaint ID or technician ID");
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "An unexpected error occurred");
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }

    private void handleGetEmployeeComplaints(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        System.out.println("handleGetEmployeeComplaints called");
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("user_id") == null) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not logged in");
                return;
            }
            
            int userId = (int) session.getAttribute("user_id");
            System.out.println("Employee ID from session: " + userId);
            
            // First check if the completion columns exist in the complaints table
            String checkColumnsSql = "SELECT COUNT(*) as column_count FROM user_tab_columns " +
                                  "WHERE table_name = 'COMPLAINTS' AND column_name IN ('COMPLETION_IMAGE_PATH', 'COMPLETION_NOTES', 'COMPLETION_DATE')";
            
            boolean hasCompletionColumns = false;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(checkColumnsSql)) {
                if (rs.next()) {
                    hasCompletionColumns = (rs.getInt("column_count") == 3);
                }
            }
            
            String sql;
            if (hasCompletionColumns) {
                sql = "SELECT c.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.user_type, " +
                      "c.completion_image_path, c.completion_notes, c.completion_date, " +
                      "t.first_name as tech_first_name, t.last_name as tech_last_name, t.email as tech_email " +
                      "FROM complaints c " +
                      "JOIN users u ON c.user_id = u.user_id " +
                      "LEFT JOIN users t ON c.assigned_to = t.user_id " +
                      "WHERE c.user_id = ? " +
                      "ORDER BY c.created_at DESC";
            } else {
                sql = "SELECT c.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.user_type, " +
                      "NULL as completion_image_path, NULL as completion_notes, NULL as completion_date, " +
                      "t.first_name as tech_first_name, t.last_name as tech_last_name, t.email as tech_email " +
                      "FROM complaints c " +
                      "JOIN users u ON c.user_id = u.user_id " +
                      "LEFT JOIN users t ON c.assigned_to = t.user_id " +
                      "WHERE c.user_id = ? " +
                      "ORDER BY c.created_at DESC";
            }
            
            System.out.println("Executing SQL: " + sql);
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, userId);
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    List<Map<String, Object>> complaints = new ArrayList<>();
                    int count = 0;
                    
                    while (rs.next()) {
                        count++;
                        Map<String, Object> complaint = new HashMap<>();
                        complaint.put("complaint_id", rs.getInt("complaint_id"));
                        complaint.put("title", rs.getString("title"));
                        complaint.put("description", rs.getString("description"));
                        complaint.put("location", rs.getString("location"));
                        complaint.put("status", rs.getString("status"));
                        complaint.put("image_path", rs.getString("image_path"));
                        complaint.put("created_at", rs.getTimestamp("created_at").toString());
                        complaint.put("first_name", rs.getString("first_name"));
                        complaint.put("last_name", rs.getString("last_name"));
                        complaint.put("email", rs.getString("email"));
                        complaint.put("phone", rs.getString("phone"));
                        complaint.put("user_type", rs.getString("user_type"));
                        
                        String completionImagePath = rs.getString("completion_image_path");
                        String completionNotes = rs.getString("completion_notes");
                        String completionDate = rs.getTimestamp("completion_date") != null ? 
                                             rs.getTimestamp("completion_date").toString() : null;
                        
                        System.out.println("Employee Complaint ID: " + rs.getInt("complaint_id") + 
                                         ", Status: " + rs.getString("status") +
                                         ", Completion Image Path: " + completionImagePath);
                        
                        complaint.put("completion_image_path", completionImagePath);
                        complaint.put("completion_notes", completionNotes);
                        complaint.put("completion_date", completionDate);
                        
                        // Add technician info if available
                        if (rs.getString("tech_first_name") != null) {
                            Map<String, String> techInfo = new HashMap<>();
                            techInfo.put("first_name", rs.getString("tech_first_name"));
                            techInfo.put("last_name", rs.getString("tech_last_name"));
                            techInfo.put("email", rs.getString("tech_email"));
                            complaint.put("assigned_technician", techInfo);
                        }
                        
                        complaints.add(complaint);
                    }
                    
                    System.out.println("Total complaints found: " + count);
                    result.put("success", true);
                    result.put("complaints", complaints);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "An unexpected error occurred");
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private void handleGetAssignedComplaints(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        System.out.println("handleGetAssignedComplaints called");
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            String userId = request.getParameter("userId");
            System.out.println("User ID from request: " + userId);
            
            if (userId == null || userId.trim().isEmpty()) {
                String errorMsg = "User ID is required";
                System.err.println(errorMsg);
                result.put("success", false);
                result.put("message", errorMsg);
                out.print(gson.toJson(result));
                return;
            }
            
            // First check if the completion columns exist in the complaints table
            String checkColumnsSql = "SELECT COUNT(*) as column_count FROM user_tab_columns " +
                                  "WHERE table_name = 'COMPLAINTS' AND column_name IN ('COMPLETION_IMAGE_PATH', 'COMPLETION_NOTES', 'COMPLETION_DATE')";
            
            boolean hasCompletionColumns = false;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(checkColumnsSql)) {
                if (rs.next()) {
                    hasCompletionColumns = (rs.getInt("column_count") == 3);
                }
            }
            
            String sql;
            if (hasCompletionColumns) {
                sql = "SELECT c.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.user_type, " +
                      "c.completion_image_path, c.completion_notes, c.completion_date " +
                      "FROM complaints c " +
                      "JOIN users u ON c.user_id = u.user_id " +
                      "WHERE c.assigned_to = ? " +
                      "ORDER BY c.created_at DESC";
            } else {
                sql = "SELECT c.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.user_type, " +
                      "NULL as completion_image_path, NULL as completion_notes, NULL as completion_date " +
                      "FROM complaints c " +
                      "JOIN users u ON c.user_id = u.user_id " +
                      "WHERE c.assigned_to = ? " +
                      "ORDER BY c.created_at DESC";
            }
            
            System.out.println("Executing SQL: " + sql);
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, Integer.parseInt(userId));
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    List<Map<String, Object>> complaints = new ArrayList<>();
                    int count = 0;
                    
                    while (rs.next()) {
                        count++;
                        Map<String, Object> complaint = new HashMap<>();
                        complaint.put("complaint_id", rs.getInt("complaint_id"));
                        complaint.put("title", rs.getString("title"));
                        complaint.put("description", rs.getString("description"));
                        complaint.put("location", rs.getString("location"));
                        complaint.put("status", rs.getString("status"));
                        complaint.put("image_path", rs.getString("image_path"));
                        complaint.put("created_at", rs.getTimestamp("created_at").toString());
                        complaint.put("first_name", rs.getString("first_name"));
                        complaint.put("last_name", rs.getString("last_name"));
                        complaint.put("email", rs.getString("email"));
                        complaint.put("phone", rs.getString("phone"));
                        complaint.put("user_type", rs.getString("user_type"));
                        String completionImagePath = rs.getString("completion_image_path");
                        String completionNotes = rs.getString("completion_notes");
                        String completionDate = rs.getTimestamp("completion_date") != null ? 
                                             rs.getTimestamp("completion_date").toString() : null;
                                             
                        System.out.println("Complaint ID: " + rs.getInt("complaint_id") + 
                                         ", Status: " + rs.getString("status") +
                                         ", Completion Image Path: " + completionImagePath);
                                         
                        complaint.put("completion_image_path", completionImagePath);
                        complaint.put("completion_notes", completionNotes);
                        complaint.put("completion_date", completionDate);
                        
                        System.out.println("Found complaint: " + complaint.get("title") + " (ID: " + complaint.get("complaint_id") + ")");
                        complaints.add(complaint);
                    }
                    
                    System.out.println("Total complaints found: " + count);
                    result.put("success", true);
                    result.put("complaints", complaints);
                }
            }
        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error retrieving assigned complaints: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private void handleUpdateComplaint(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        Gson gson = new Gson();
        Map<String, Object> result = new HashMap<>();
        
        try (Connection conn = OracleDBConnection.getConnection()) {
            // Start transaction
            conn.setAutoCommit(false);
            
            try {
                // Get parameters
                int complaintId = Integer.parseInt(request.getParameter("complaintId"));
                String status = request.getParameter("status");
                String notes = request.getParameter("notes");
                
                // Handle file upload if status is COMPLETED
                String completionImagePath = null;
                Part filePart = request.getPart("completionImage");
                
                if ("COMPLETED".equals(status) && filePart != null && filePart.getSize() > 0) {
                    // Create completion_images directory if it doesn't exist
                    String uploadPath = getServletContext().getRealPath("/completion_images");
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    
                    // Generate unique filename
                    String fileName = filePart.getSubmittedFileName();
                    String fileExtension = "";
                    int i = fileName.lastIndexOf('.');
                    if (i > 0) {
                        fileExtension = fileName.substring(i);
                    }
                    String uniqueFileName = "completion_" + System.currentTimeMillis() + fileExtension;
                    completionImagePath = "completion_images/" + uniqueFileName;
                    
                    // Save file
                    filePart.write(uploadPath + File.separator + uniqueFileName);
                }
                
                // Update complaint status and completion details
                String sql = "UPDATE complaints SET status = ?, updated_at = CURRENT_TIMESTAMP, " +
                           "completion_notes = ?" +
                           (completionImagePath != null ? ", completion_image_path = ?" : "") + 
                           " WHERE complaint_id = ?";
                
                System.out.println("Executing SQL: " + sql);
                System.out.println("Parameters: status=" + status + 
                                 ", notes=" + notes + 
                                 (completionImagePath != null ? ", imagePath=" + completionImagePath : "") + 
                                 ", complaintId=" + complaintId);
                
                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                    int paramIndex = 1;
                    pstmt.setString(paramIndex++, status);
                    pstmt.setString(paramIndex++, notes != null ? notes : "");
                    if (completionImagePath != null) {
                        pstmt.setString(paramIndex++, completionImagePath);
                    }
                    pstmt.setInt(paramIndex, complaintId);
                    
                    int rowsAffected = pstmt.executeUpdate();
                    System.out.println("Rows affected: " + rowsAffected);
                    
                    if (rowsAffected > 0) {
                        conn.commit();
                        result.put("success", true);
                        result.put("message", "Status updated successfully");
                        System.out.println("Complaint " + complaintId + " updated successfully");
                    } else {
                        String errorMsg = "No complaint found with ID: " + complaintId;
                        System.out.println(errorMsg);
                        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                        result.put("success", false);
                        result.put("message", errorMsg);
                    }
                }
                
            } catch (Exception e) {
                // Rollback transaction on error
                if (conn != null) {
                    try {
                        conn.rollback();
                    } catch (SQLException ex) {
                        ex.printStackTrace();
                    }
                }
                throw e;
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            result.put("success", false);
            result.put("message", "Error updating complaint: " + e.getMessage());
        }
        
        out.print(gson.toJson(result));
        out.flush();
    }

    private void handleViewComplaint(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        com.google.gson.Gson gson = new com.google.gson.Gson(); 
        Map<String, Object> jsonResponse = new HashMap<>();

        try {
            String complaintIdStr = request.getParameter("complaintId");
            if (complaintIdStr == null || complaintIdStr.isEmpty()) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Complaint ID is required.");
                out.print(gson.toJson(jsonResponse));
                out.flush();
                return;
            }

            int complaintId = Integer.parseInt(complaintIdStr);
            Connection conn = OracleDBConnection.getConnection();
            
            String sql = "SELECT c.*, u.username as reporter_username, u.email as reporter_email, " +
                         "tech.username as technician_username, tech.email as technician_email " +
                         "FROM complaints c " +
                         "JOIN users u ON c.user_id = u.user_id " +
                         "LEFT JOIN users tech ON c.assigned_to = tech.user_id " +
                         "WHERE c.complaint_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, complaintId);
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Map<String, Object> complaintDetails = new HashMap<>();
                complaintDetails.put("complaint_id", rs.getInt("complaint_id"));
                complaintDetails.put("user_id", rs.getInt("user_id"));
                complaintDetails.put("reporter_username", rs.getString("reporter_username"));
                complaintDetails.put("reporter_email", rs.getString("reporter_email"));
                complaintDetails.put("title", rs.getString("title"));
                complaintDetails.put("description", rs.getString("description"));
                complaintDetails.put("location_lat", rs.getObject("location_lat")); 
                complaintDetails.put("location_lng", rs.getObject("location_lng")); 
                complaintDetails.put("image_path", rs.getString("image_path"));
                complaintDetails.put("status", rs.getString("status"));
                complaintDetails.put("assigned_to", rs.getObject("assigned_to")); 
                complaintDetails.put("technician_username", rs.getString("technician_username")); 
                complaintDetails.put("technician_email", rs.getString("technician_email")); 
                complaintDetails.put("created_at", rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toString() : null);
                complaintDetails.put("updated_at", rs.getTimestamp("updated_at") != null ? rs.getTimestamp("updated_at").toString() : null);

                jsonResponse.put("success", true);
                jsonResponse.put("complaint", complaintDetails);
            } else {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Complaint not found.");
            }
            
            rs.close();
            pstmt.close();

        } catch (NumberFormatException e) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Invalid Complaint ID format.");
            e.printStackTrace(); 
        } catch (Exception e) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "An error occurred while retrieving complaint details: " + e.getMessage());
            e.printStackTrace(); 
        }
        out.print(gson.toJson(jsonResponse));
        out.flush();
    }
}
