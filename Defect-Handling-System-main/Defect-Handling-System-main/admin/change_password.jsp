<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpSession" %>

<%
    // Ensure user is logged in
    session = request.getSession(false);
    if (session == null || session.getAttribute("user_id") == null) {
        response.sendRedirect("../login.jsp?message=Please login to change your password.");
        return;
    }
    String username = (String) session.getAttribute("username");
    String userType = (String) session.getAttribute("user_type");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Change Password - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .form-container {
            max-width: 500px;
            margin: 50px auto;
            padding: 30px;
            border: 1px solid #ddd;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .messages div {
            margin-bottom: 15px;
        }
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
                    <%
                        String dashboardUrl = "#"; // Default/fallback URL
                        String dashboardText = "Dashboard"; // Default text

                        if ("ADMIN".equals(userType)) {
                            dashboardUrl = "dashboard.jsp"; // Relative to admin folder
                            dashboardText = "Admin Dashboard";
                    %>
                        <li class="nav-item"><a class="nav-link" href="<%= dashboardUrl %>"><%= dashboardText %></a></li>
                        <li class="nav-item"><a class="nav-link" href="manage_users.jsp">Manage Users</a></li>
                    <%
                        } else if ("EMPLOYEE".equals(userType)) {
                            dashboardUrl = "../employee/dashboard.jsp"; // Relative to project root then employee folder
                            dashboardText = "Employee Dashboard";
                    %>
                        <li class="nav-item"><a class="nav-link" href="<%= dashboardUrl %>"><%= dashboardText %></a></li>
                    <%
                        } else if ("TECHNICIAN".equals(userType)) {
                            dashboardUrl = "../technician/dashboard.jsp"; // Relative to project root then technician folder
                            dashboardText = "Technician Dashboard";
                    %>
                        <li class="nav-item"><a class="nav-link" href="<%= dashboardUrl %>"><%= dashboardText %></a></li>
                    <%
                        } else { // Fallback for any other user types or if userType is null/unexpected
                    %>
                        <li class="nav-item"><a class="nav-link" href="../login.jsp">Return to Login</a></li>
                    <%
                        }
                    %>
                    <li class="nav-item">
                        <a class="nav-link active" href="change_password.jsp">Change Password</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../LogoutServlet">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="form-container">
            <h2 class="text-center mb-4">Change Your Password</h2>
            
            <div id="messages" class="messages">
                <!-- Messages from servlet will be displayed here -->
            </div>

            <form id="changePasswordForm">
                <div class="mb-3">
                    <label for="currentPassword" class="form-label">Current Password</label>
                    <input type="password" class="form-control" id="currentPassword" name="currentPassword" required>
                </div>
                <div class="mb-3">
                    <label for="newPassword" class="form-label">New Password</label>
                    <input type="password" class="form-control" id="newPassword" name="newPassword" required>
                </div>
                <div class="mb-3">
                    <label for="confirmNewPassword" class="form-label">Confirm New Password</label>
                    <input type="password" class="form-control" id="confirmNewPassword" name="confirmNewPassword" required>
                </div>
                <button type="submit" class="btn btn-primary w-100">Change Password</button>
            </form>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        $(document).ready(function() {
            $('#changePasswordForm').on('submit', function(e) {
                e.preventDefault();
                $('#messages').html(''); // Clear previous messages

                var newPassword = $('#newPassword').val();
                var confirmNewPassword = $('#confirmNewPassword').val();

                if (newPassword !== confirmNewPassword) {
                    $('#messages').html('<div class=\"alert alert-danger\">New passwords do not match.</div>');
                    return;
                }

                // Basic password strength (example: at least 6 chars)
                if (newPassword.length < 6) {
                     $('#messages').html('<div class=\"alert alert-danger\">New password must be at least 6 characters long.</div>');
                    return;
                }

                $.ajax({
                    url: '../UserManagementServlet', // Corrected path
                    type: 'POST',
                    data: $(this).serialize() + '&action=changePassword',
                    dataType: 'json', // Expect JSON response
                    success: function(response) {
                        if (response.success) {
                            $('#messages').html('<div class=\"alert alert-success\">' + response.message + '</div>');
                            $('#changePasswordForm')[0].reset(); // Clear form
                        } else {
                            $('#messages').html('<div class=\"alert alert-danger\">' + response.message + '</div>');
                        }
                    },
                    error: function(xhr, status, error) {
                        $('#messages').html('<div class=\"alert alert-danger\">An error occurred: ' + xhr.responseText + '</div>');
                    }
                });
            });
        });
    </script>
</body>
</html>
