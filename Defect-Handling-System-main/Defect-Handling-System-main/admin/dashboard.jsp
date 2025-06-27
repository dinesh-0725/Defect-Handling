<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching of secure pages
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0
    response.setDateHeader("Expires", 0); // Proxies
%>
<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in and is an admin
    if (session == null || session.getAttribute("user_type") == null || !session.getAttribute("user_type").equals("ADMIN")) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .dashboard-card {
            margin-bottom: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .preview-image {
            max-width: 100px;
            max-height: 100px;
        }
        .assign-form {
            display: none;
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
                        <span class="nav-link">Welcome, <%= session.getAttribute("username") %></span>
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

    <div class="container mt-4">
        <div class="row">
            <div class="col-md-6">
                <div class="dashboard-card">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">Pending Complaints</h4>
                            <div class="btn-group">
                                <button type="button" class="btn btn-primary" onclick="refreshComplaints()">
                                    <i class="fas fa-sync"></i> Refresh
                                </button>
                            </div>
                        </div>
                        <div class="card-body">
                            <div id="complaintsList"></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="dashboard-card">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0">User Management</h4>
                        </div>
                        <div class="card-body">
                            <p>Manage user accounts and security settings.</p>
                            <a href="manage_users.jsp" class="btn btn-primary">
                                <i class="fas fa-users-cog"></i> Manage Users
                            </a>
                            <a href="change_password.jsp" class="btn btn-info ms-2">
                                <i class="fas fa-key"></i> Change Own Password
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for Assigning Complaint -->
    <div class="modal fade" id="assignModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Assign Complaint</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="assignForm">
                        <input type="hidden" id="complaintId" name="complaintId">
                        <div class="mb-3">
                            <label for="technician" class="form-label">Select Technician</label>
                            <select class="form-select" id="technician" name="technicianId" required>
                                <!-- Technicians will be populated by JavaScript -->
                            </select>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="button" class="btn btn-primary" onclick="assignComplaint()">Assign</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        $(document).ready(function() {
            console.log('Document ready, initializing...');
            initializeModal();
            loadTechnicians();
            loadComplaints();
        });

        function initializeModal() {
            console.log('Initializing modal...');
            // Initialize the modal manually
            var assignModal = new bootstrap.Modal(document.getElementById('assignModal'), {
                keyboard: false
            });
            
            // Store the modal instance for later use
            window.assignModal = assignModal;
            
            // Log when modal is shown
            $('#assignModal').on('shown.bs.modal', function () {
                console.log('Assign modal shown');
                // Refresh technicians when modal is shown
                loadTechnicians();
            });
        }

        function loadTechnicians() {
            console.log('Loading technicians...');
            $.ajax({
                url: '../ComplaintServlet',
                type: 'GET',
                data: { action: 'getTechnicians' },
                dataType: 'json',
                success: function(response) {
                    console.log('Technicians response:', response);
                    if (response && response.success) {
                        let technicians = response.technicians || [];
                        let select = $('#technician');
                        
                        // Clear existing options
                        select.empty();
                        
                        // Always add a default option first
                        select.append($('<option>', {
                            value: '',
                            text: 'Select a technician',
                            selected: true,
                            disabled: true
                        }));
                        
                        if (technicians.length > 0) {
                            // Add technician options
                            technicians.forEach(tech => {
                                if (tech && tech.id) {
                                    // Display just the name without email in parentheses
                                    let displayName = tech.name || 'Unnamed Technician';
                                    // Use tech.id as the value, not tech.name
                                    select.append($('<option>', {
                                        value: tech.id,
                                        text: displayName
                                    }));
                                }
                            });
                            
                            console.log('Technicians loaded successfully');
                            console.log('Dropdown options:', select.find('option').map((i, opt) => $(opt).text()).get());
                        } else {
                            console.warn('No technicians found');
                            select.append($('<option>', {
                                value: '',
                                text: 'No technicians available',
                                disabled: true
                            }));
                        }
                    } else {
                        console.error('Error in response:', response);
                        select.html($('<option>', {
                            value: '',
                            text: 'Error loading technicians',
                            disabled: true
                        }));
                    }
                },
                error: function(xhr, status, error) {
                    console.error('AJAX Error:', status, error);
                    console.error('Response:', xhr.responseText);
                    $('#technician').html($('<option>', {
                        value: '',
                        text: 'Error loading technicians',
                        disabled: true
                    }));
                }
            });
        }

        function loadComplaints() {
            console.log('Loading complaints...');
            $.ajax({
                url: '../ComplaintServlet',
                type: 'GET',
                data: { action: 'getPendingComplaints' },
                dataType: 'json',
                success: function(response) {
                    console.log('Complaints response:', response);
                    if (response && response.success) {
                        displayComplaints(response.complaints || []);
                    } else {
                        console.error('Error in response:', response);
                        alert('Failed to load complaints: ' + (response ? response.message : 'Unknown error'));
                    }
                },
                error: function(xhr, status, error) {
                    console.error('AJAX Error:', status, error);
                    console.error('Response:', xhr.responseText);
                    alert('Error loading complaints. Check console for details.');
                }
            });
        }

        function displayComplaints(complaints) {
            let html = '<div class="table-responsive">'
                        + '<table class="table">'
                        + '<thead>'
                        + '<tr>'
                        + '<th>Title</th>'
                        + '<th>Location</th>'
                        + '<th>Status</th>'
                        + '<th>Image</th>'
                        + '<th>Actions</th>'
                        + '</tr>'
                        + '</thead>'
                        + '<tbody>';

            complaints.forEach(complaint => {
                html += '<tr>';
                html += '<td>' + complaint.title + '</td>';
                html += '<td>' + complaint.location + '</td>';
                html += '<td>' + complaint.status + '</td>';
                html += '<td>';
                if (complaint.image_path) {
                    // Use the full path to the image
                    html += '<img src="../' + complaint.image_path + '" class="preview-image" style="max-width: 100px; max-height: 100px;" alt="Complaint Image">';
                } else {
                    html += 'No image';
                }
                html += '</td>';
                html += '<td>';
                if (complaint.status === 'PENDING') {
                    html += '<button class="btn btn-primary btn-sm" onclick="showAssignModal(' + complaint.complaint_id + ')">Assign</button>';
                }
                html += '</td>';
                html += '</tr>';
            });

            html += '</tbody></table></div>';
            $('#complaintsList').html(html);
        }

        function showAssignModal(complaintId) {
            $('#complaintId').val(complaintId);
            $('#assignModal').modal('show');
        }

        function assignComplaint() {
            $.ajax({
                url: '../ComplaintServlet',
                type: 'POST',
                data: $('#assignForm').serialize() + '&action=assign',
                success: function(response) {
                    if (response.success) {
                        $('#assignModal').modal('hide');
                        loadComplaints();
                        alert('Complaint assigned successfully!');
                    } else {
                        alert('Error: ' + response.message);
                    }
                },
                error: function() {
                    alert('An error occurred. Please try again.');
                }
            });
        }

        function refreshComplaints() {
            loadComplaints();
        }
    </script>
</body>
</html>
