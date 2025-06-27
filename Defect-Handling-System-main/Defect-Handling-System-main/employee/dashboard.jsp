<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page session="true" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
%>

<html>
    <head>
        <title>Employee Complaint Dashboard</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            /* Image preview modal styles */
            .modal-image-preview {
                max-width: 90%;
                max-height: 80vh;
                margin: 0 auto;
                display: block;
            }
            
            .clickable-image {
                cursor: pointer;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                max-height: 100px;
                border-radius: 6px;
                border: 1px solid #ddd;
            }
            
            .clickable-image:hover {
                transform: scale(1.05);
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
            }
            
            .modal-content {
                background: transparent;
                border: none;
            }
            
            .modal-header {
                border: none;
                justify-content: flex-end;
                padding: 0.5rem 0.5rem 0 0;
            }
            
            .btn-close {
                background: white;
                opacity: 1;
                font-size: 1.5rem;
                padding: 0.5rem;
            }
            body {
                background-color: #f8f9fa;
                
            }
    
            .dashboard-container {
                max-width: 95%;
                margin: 80px auto 40px auto;
                padding: 20px;
                background: #fff;
                border-radius: 10px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                position: relative;
                z-index: 1;
            }
    
            h2 {
                color: #343a40;
                margin-bottom: 30px;
            }
    
            table {
                width: 100%;
            }
    
            th {
                background-color: #007bff;
                color: white;
            }
    
            td, th {
                vertical-align: middle !important;
            }
    
            .table img {
                max-height: 100px;
                border-radius: 6px;
                border: 1px solid #ddd;
            }
    
            .table-striped > tbody > tr:nth-of-type(odd) {
                background-color: #f2f2f2;
            }
        </style>
    </head>
    <body>
       

        <nav class="navbar navbar-expand-lg navbar-dark bg-primary fixed-top">
            <div class="container">
                <a class="navbar-brand" href="#">Steel Plant Detection System</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item">
                            <span class="nav-link">Welcome, <%= session.getAttribute("username") %></span>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="../admin/change_password.jsp">Change Own Password</a>
                        </li>
                        <li class="nav-item">
                            <form action="${pageContext.request.contextPath}/LogoutServlet" method="POST" style="display: inline;">
                                <button type="submit" class="nav-link" style="background: none; border: none; cursor: pointer;">Logout</button>
                            </form>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
        
        <div class="dashboard-container">
            <h2 class="text-center">My Complaints</h2>
            <a href="../employee/complaint-registration.jsp" style="margin-top: -65px; margin-left: 1200px;" class="btn btn-primary">Add New Complaint</a>
            <table class="table table-bordered table-striped table-hover text-center align-middle">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Description</th>
                        <th>Status</th>
                        <th>Location</th>
                        <th>Image</th>
                        <th>Completion Image</th>
                    </tr>
                </thead>
                <tbody>
                    
    <%
        try {
            conn = OracleDBConnection.getConnection();
            String sql = "SELECT complaint_id, title, description, location, status,image_path, completion_image_path " +
                        "FROM complaints WHERE user_id = ? " +
                        "ORDER BY created_at DESC";
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, userId);
            rs = stmt.executeQuery();
    
            while (rs.next()) {
                String imagePath = rs.getString("image_path");
                String completionImagePath = rs.getString("completion_image_path");
                String cleanedPath = (imagePath != null && imagePath.startsWith("/"))
                                   ? imagePath.substring(1)
                                   : imagePath;
                String cleanedCompletionPath = (completionImagePath != null && completionImagePath.startsWith("/"))
                                   ? completionImagePath.substring(1)
                                   : completionImagePath;
    %>
    <tr>
       
        <td><%= rs.getString("title") %></td>
        <td><%= rs.getString("description") %></td>
        <td><%= rs.getString("status") %></td>
        <td><%= rs.getString("location") %></td>
        <td>
            <%
                if (imagePath != null && !imagePath.isEmpty()) {
            %>
                <img src="../<%= cleanedPath %>" alt="Completed Image" class="clickable-image" onclick="openImageModal(this.src)" />
            <%
                } else {
                    out.print("N/A");
                }
            %>
        </td>
        <td>
            <%
                if (completionImagePath != null && !completionImagePath.isEmpty()) {
            %>
                <img src="../<%= cleanedCompletionPath %>" alt="Completion Image" class="clickable-image" onclick="openImageModal(this.src)" />
            <%
                } else {
                    out.print("N/A");
                }
            %>
        </td>
    </tr>
    <%
            }
        } catch (Exception e) {
            out.println("<tr><td colspan='6'>Error: " + e.getMessage() + "</td></tr>");
            e.printStackTrace();
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
    %>
    </tbody>
    </table>
        </div>
        
        <!-- Image Preview Modal -->
        <div class="modal fade" id="imageModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">&times;</button>
                    </div>
                    <div class="modal-body text-center">
                        <img id="modalImage" src="" alt="Preview" class="modal-image-preview">
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            function openImageModal(imageSrc) {
                const modal = new bootstrap.Modal(document.getElementById('imageModal'));
                document.getElementById('modalImage').src = imageSrc;
                modal.show();
            }
            
            // Close modal when clicking outside the image
            document.getElementById('imageModal').addEventListener('click', function(e) {
                if (e.target === this) {
                    bootstrap.Modal.getInstance(this).hide();
                }
            });
        </script>
    </body>
</html>
