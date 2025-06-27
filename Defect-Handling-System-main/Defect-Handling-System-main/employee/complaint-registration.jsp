<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is logged in and is an employee
    if (session == null || session.getAttribute("user_type") == null || !session.getAttribute("user_type").equals("EMPLOYEE")) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Complaint Registration - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .registration-card {
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .preview-image {
            max-width: 200px;
            max-height: 200px;
            margin-top: 10px;
        }
        .error-message {
            color: red;
            font-size: 0.9em;
            margin-top: 5px;
        }
        .success-message {
            color: green;
            font-size: 0.9em;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="#">Steel Plant Detection System</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <span class="nav-link">Welcome, <%= session.getAttribute("username") %></span>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../LogoutServlet">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="registration-card">
            <h2 class="text-center mb-4">Register New Complaint</h2>
            
            <div id="messageDiv" class="mb-3"></div>
            
            <form id="complaintForm" enctype="multipart/form-data">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="title" class="form-label">Complaint Title <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="title" name="title" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="location" class="form-label">Location <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="location" name="location" required>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="description" class="form-label">Description <span class="text-danger">*</span></label>
                    <textarea class="form-control" id="description" name="description" rows="4" required></textarea>
                </div>

                <div class="mb-3">
                    <label for="image" class="form-label">Upload Image <span class="text-danger">*</span></label>
                    <input type="file" class="form-control" id="image" name="image" accept="image/*" required>
                    <div id="imagePreview"></div>
                </div>

                <!-- Only include fields that exist in the database schema -->

                <div class="mb-3">
                    <button type="submit" class="btn btn-primary w-100">Submit Complaint</button>
                </div>
            </form>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        $(document).ready(function() {
            // Handle image preview
            $('#image').on('change', function() {
                const file = this.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        $('#imagePreview').html('<img src="' + e.target.result + '" class="preview-image" alt="Preview">');
                    }
                    reader.readAsDataURL(file);
                }
            });

            // Form submission
            $('#complaintForm').on('submit', function(e) {
                e.preventDefault();
                
                // Show loading state
                $('#messageDiv').html('<div class="text-center"><i class="fas fa-spinner fa-spin"></i> Submitting...</div>');
                
                const formData = new FormData(this);
                // Don't send action parameter - let the servlet handle it as a new complaint
                formData.append('userId', '<%= session.getAttribute("user_id") %>');
                
                // Log form data for debugging
                for (let [key, value] of formData.entries()) {
                    console.log(key + ': ' + value);
                }
                
                $.ajax({
                    url: '../ComplaintServlet',
                    type: 'POST',
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function(response) {
                        console.log('Server response:', response);
                        try {
                            // Check if response is already an object or needs parsing
                            const result = typeof response === 'string' ? JSON.parse(response) : response;
                            
                            if (result.success) {
                                $('#messageDiv').html('<div class="alert alert-success">Complaint registered successfully! Redirecting...</div>');
                                setTimeout(function() {
                                    window.location.href = 'dashboard.jsp';
                                }, 2000);
                            } else {
                                const errorMsg = result.message || 'An unknown error occurred';
                                $('#messageDiv').html('<div class="alert alert-danger">Error: ' + errorMsg + '</div>');
                            }
                        } catch (e) {
                            console.error('Error parsing server response:', e);
                            $('#messageDiv').html('<div class="alert alert-danger">Error processing server response. Please check console for details.</div>');
                        }
                    },
                    error: function() {
                        $('#messageDiv').html('<div class="error-message">An error occurred. Please try again.</div>');
                    }
                });
            });
        });
    </script>
</body>
</html>
