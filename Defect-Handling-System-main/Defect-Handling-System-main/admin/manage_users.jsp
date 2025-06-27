<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpSession" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>

<%
    session = request.getSession(false); // Use the implicit session object
    if (session == null || session.getAttribute("user_type") == null || !session.getAttribute("user_type").equals("ADMIN")) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String username = (String) session.getAttribute("username");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Users - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        /* Add any specific styles for this page if needed */
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="dashboard.jsp">Steel Plant Detection System</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <span class="nav-link">Welcome, <%= username %></span>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../LogoutServlet">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="pb-2 mt-4 mb-2 border-bottom">
            <h2>Manage Users</h2>
        </div>

        <!-- User list will be displayed here -->
        <p>User management features will be implemented here. This includes listing users, and options to edit details or change passwords.</p>
        
        <!-- Placeholder for future content like a table of users -->
        <div id="userListContainer">
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th>User ID</th>
                            <th>Username</th>
                            <th>First Name</th>
                            <th>Last Name</th>
                            <th>User Type</th>
                            <th>Address</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            Connection conn = null;
                            Statement stmt = null;
                            ResultSet rs = null;
                            try {
                                conn = OracleDBConnection.getConnection();
                                if (conn == null) {
                                    out.println("<tr><td colspan='7' class='text-danger'>Error: Could not connect to the database.</td></tr>");
                                } else {
                                    String sql = "SELECT user_id, username, first_name, last_name, user_type, address FROM USERS ORDER BY user_id ASC";
                                    stmt = conn.createStatement();
                                    rs = stmt.executeQuery(sql);

                                    boolean foundUsers = false;
                                    while (rs.next()) {
                                        foundUsers = true;
                        %>
                        <tr>
                            <td><%= rs.getInt("user_id") %></td>
                            <td><%= rs.getString("username") %></td>
                            <td><%= rs.getString("first_name") == null ? "" : rs.getString("first_name") %></td>
                            <td><%= rs.getString("last_name") == null ? "" : rs.getString("last_name") %></td>
                            <td><%= rs.getString("user_type") %></td>
                            <td><%= rs.getString("address") == null ? "" : rs.getString("address") %></td>
                            <td>
                                <button class="btn btn-sm btn-warning" onclick="alert('Edit user <%= rs.getInt("user_id") %> - functionality to be implemented.')"><i class="fas fa-edit"></i> Edit</button>
                                <!-- Add Change Password button later -->
                            </td>
                        </tr>
                        <%
                                    }
                                    if (!foundUsers) {
                                        out.println("<tr><td colspan='7'>No users found.</td></tr>");
                                    }
                                }
                            } catch (SQLException se) {
                                out.println("<tr><td colspan='7' class='text-danger'>SQL Error: " + se.getMessage() + "</td></tr>");
                                se.printStackTrace(response.getWriter());
                            } catch (Exception e) {
                                out.println("<tr><td colspan='7' class='text-danger'>Error: " + e.getMessage() + "</td></tr>");
                                e.printStackTrace(response.getWriter());
                            } finally {
                                try {
                                    if (rs != null) rs.close();
                                    if (stmt != null) stmt.close();
                                    // Connection is managed by OracleDBConnection, typically not closed here per request unless it's pooled and released.
                                    // For simplicity here, we are not closing conn, assuming OracleDBConnection handles its lifecycle or it's a singleton connection.
                                } catch (SQLException sqle) {
                                    sqle.printStackTrace(response.getWriter());
                                }
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // JavaScript for future enhancements (e.g., AJAX-based updates) can go here.
        $(document).ready(function() {
            // Page is ready
        });
    </script>
</body>
</html>
