<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.servlet.http.HttpSession" %>

<%
    HttpSession session = request.getSession(false);
    if (session == null || session.getAttribute("user_type") == null || !session.getAttribute("user_type").equals("ADMIN")) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Complaint Redirection - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .redirection-card {
            max-width: 1200px;
            margin: 50px auto;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .preview-image {
            max-width: 200px;
            max-height: 200px;
        }
        .status-badge {
            padding: 5px 10px;
            border-radius: 15px;
        }
        .status-pending { background-color: #ffc107; color: #000; }
        .status-assigned { background-color: #28a745; color: #fff; }
        .priority-badge {
            padding: 3px 8px;
            border-radius: 10px;
        }
        .priority-low { background-color: #28a745; color: #fff; }
        .priority-medium { background-color: #ffc107; color: #000; }
        .priority-high { background-color: #dc3545; color: #fff; }
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
        <div class="redirection-card">
            <h2 class="text-center mb-4">Complaint Redirection</h2>
            
            <div id="messageDiv" class="mb-3"></div>
            
            <div class="row">
                <!-- Filters -->
                <div class="col-md-3 mb-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">Filters</h5>
                        </div>
                        <div class="card-body">
                            <div class="mb-3">
                                <label for="priorityFilter" class="form-label">Priority Level</label>
                                <select class="form-select" id="priorityFilter">
                                    <option value="">All Priorities</option>
                                    <option value="LOW">Low</option>
                                    <option value="MEDIUM">Medium</option>
                                    <option value="HIGH">High</option>
                                </select>
                            </div>
                            <div class="mb-3">
                                <label for="equipmentFilter" class="form-label">Equipment</label>
                                <input type="text" class="form-control" id="equipmentFilter" placeholder="Filter by equipment">
                            </div>
                            <div class="mb-3">
                                <label for="locationFilter" class="form-label">Location</label>
                                <input type="text" class="form-control" id="locationFilter" placeholder="Filter by location">
                            </div>
                            <button class="btn btn-primary w-100" onclick="applyFilters()">Apply Filters</button>
                        </div>
                    </div>
                </div>

                <!-- Complaint List -->
                <div class="col-md-9">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 class="mb-0">Pending Complaints</h5>
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
                            <select class="form-select" id="technician" name="technician" required>
                                <!-- Technicians will be populated by JavaScript -->
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="notes" class="form-label">Additional Notes</label>
                            <textarea class="form-control" id="notes" name="notes" rows="3" placeholder="Add any additional instructions for the technician"></textarea>
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
            loadTechnicians();
            loadComplaints();
        });

        function loadTechnicians() {
            $.ajax({
                url: '../ComplaintServlet?action=getTechnicians',
                type: 'GET',
                success: function(response) {
                    if (response.success) {
                        let technicians = response.technicians;
                        let select = $('#technician');
                        select.empty();
                        
                        technicians.forEach(tech => {
                            select.append(`<option value="${tech.user_id}">${tech.first_name} ${tech.last_name} (${tech.specialization})</option>`);
                        });
                    }
                },
                error: function() {
                    alert('Error loading technicians');
                }
            });
        }

        function loadComplaints() {
            $.ajax({
                url: '../ComplaintServlet?action=getPendingComplaints',
                type: 'GET',
                success: function(response) {
                    if (response.success) {
                        displayComplaints(response.complaints);
                    }
                },
                error: function() {
                    alert('Error loading complaints');
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
                        + '<th>Priority</th>'
                        + '<th>Status</th>'
                        + '<th>Equipment</th>'
                        + '<th>Image</th>'
                        + '<th>Actions</th>'
                        + '</tr>'
                        + '</thead>'
                        + '<tbody>';

            complaints.forEach(complaint => {
                html += '<tr>';
                html += '<td>' + complaint.title + '</td>';
                html += '<td>' + complaint.location + '</td>';
                
                // Priority badge
                let priorityBadge = '<span class="priority-badge priority-' + complaint.priority.toLowerCase() + '">';
                priorityBadge += complaint.priority;
                priorityBadge += '</span>';
                
                html += '<td>' + priorityBadge + '</td>';
                
                // Status badge
                let statusBadge = '<span class="status-badge status-' + complaint.status.toLowerCase() + '">';
                statusBadge += complaint.status;
                statusBadge += '</span>';
                
                html += '<td>' + statusBadge + '</td>';
                html += '<td>' + (complaint.equipment || '-') + '</td>';
                html += '<td><img src="' + complaint.image_path + '" class="preview-image" alt="Complaint Image"></td>';
                html += '<td>';
                
                // Show assign button only for PENDING complaints
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
            $('#notes').val(''); // Clear notes
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
                        $('#messageDiv').html('<div class="success-message">Complaint assigned successfully!</div>');
                        loadComplaints();
                    } else {
                        $('#messageDiv').html('<div class="error-message">Error: ' + response.message + '</div>');
                    }
                },
                error: function() {
                    $('#messageDiv').html('<div class="error-message">An error occurred. Please try again.</div>');
                }
            });
        }

        function refreshComplaints() {
            loadComplaints();
        }

        function applyFilters() {
            const priority = $('#priorityFilter').val();
            const equipment = $('#equipmentFilter').val();
            const location = $('#locationFilter').val();
            
            $.ajax({
                url: '../ComplaintServlet',
                type: 'GET',
                data: {
                    action: 'getFilteredComplaints',
                    priority: priority,
                    equipment: equipment,
                    location: location
                },
                success: function(response) {
                    if (response.success) {
                        displayComplaints(response.complaints);
                    }
                },
                error: function() {
                    alert('Error applying filters');
                }
            });
        }
    </script>
</body>
</html>
