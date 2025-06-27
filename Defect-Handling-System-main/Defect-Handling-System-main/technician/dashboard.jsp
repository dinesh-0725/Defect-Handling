<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.steelplant.db.OracleDBConnection" %>
<%@ page import="java.util.*" %>

<%
    if (session == null || session.getAttribute("user_type") == null || !"TECHNICIAN".equals(session.getAttribute("user_type"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Technician Dashboard - Steel Plant Detection System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <style>
        .dashboard-card {
            margin-bottom: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .preview-image {
            max-width: 100px;
            max-height: 100px;
        }
        .status-badge {
            padding: 5px 10px;
            border-radius: 15px;
        }
        .status-in-progress { background-color: #ffc107; color: #000; }
        .status-completed { background-color: #28a745; color: #fff; }
        .status-closed { background-color: #6c757d; color: #fff; }
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
                        <a class="nav-link" href="../admin/change_password.jsp">Change Own Password</a>
                    </li>
                    <li class="nav-item">
                        <form action="${pageContext.request.contextPath}/LogoutServlet" method="POST" style="display: inline;">
                            <button type="submit" class="nav-link" style="background: none; border: none; cursor: pointer; padding: 0.5rem 1rem;">Logout</button>
                        </form>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row">
            <div class="col-md-12">
                <div class="dashboard-card">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">Assigned Work</h4>
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

    <!-- Image Preview Modal -->
    <div class="modal fade" id="imageModal" tabindex="-1" aria-labelledby="imageModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header bg-light">
                    <h5 class="modal-title" id="imageModalLabel">Image Preview</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body text-center p-0">
                    <div class="d-flex justify-content-center align-items-center" style="min-height: 400px;">
                        <img id="modalImage" src="" class="img-fluid" style="max-height: 75vh; max-width: 100%; object-fit: contain;" 
                             alt="Image Preview" onerror="this.src='${pageContext.request.contextPath}/completion_images/image-not-found.png';">
                    </div>
                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for Updating Complaint Status -->
    <div class="modal fade" id="statusModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Update Status</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="statusForm" onsubmit="updateStatus(); return false;">
                        <input type="hidden" name="complaintId" id="complaintId">
                        <div class="mb-3">
                            <label for="status" class="form-label">Status</label>
                            <select class="form-select" id="status" name="status" onchange="toggleCompletionImage(this)" required>
                                <option value="">Select Status</option>
                                <option value="IN_PROGRESS">In Progress</option>
                                <option value="COMPLETED">Completed</option>
                                <option value="CLOSED">Closed</option>
                            </select>
                        </div>
                        <div class="mb-3" id="completionImageDiv" style="display: none;">
                            <label for="completionImage" class="form-label">
                                Completion Image <span class="text-danger">*</span>
                            </label>
                            <input type="file" class="form-control" id="completionImage" name="completionImage" accept="image/*">
                            <div class="form-text text-danger" id="imageError" style="display: none;">
                                Please upload a completion image
                            </div>
                        </div>
                        <div id="imagePreview" class="mt-2"></div>
                        <div class="mb-3">
                            <label for="notes" class="form-label">Notes (Optional)</label>
                            <textarea class="form-control" id="notes" name="notes" rows="3"></textarea>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="button" class="btn btn-primary" onclick="updateStatus()">Update Status</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
    // Function to show image in modal
    function showImageModal(imageUrl) {
        console.log('Original image URL:', imageUrl);
        
        let fullImageUrl;
        const contextPath = '${pageContext.request.contextPath}';
        
        // If it's already a full URL, use as is
        if (imageUrl.startsWith('http')) {
            fullImageUrl = imageUrl;
        }
        // If it already contains the context path, ensure it's not duplicated
        else if (imageUrl.includes(contextPath)) {
            fullImageUrl = imageUrl;
        }
        // If it's a root-relative path (starts with /)
        else if (imageUrl.startsWith('/')) {
            // Remove any leading slashes to prevent double slashes
            const cleanPath = imageUrl.replace(/^\/+/g, '');
            fullImageUrl = contextPath + '/' + cleanPath;
        }
        // For any other case, assume it's a relative path
        else {
            fullImageUrl = contextPath + '/' + imageUrl;
        }
        
        console.log('Full image URL:', fullImageUrl);
        
        // Set the image source and show the modal
        const modalImage = document.getElementById('modalImage');
        modalImage.src = fullImageUrl;
        
        // Handle image load errors
        modalImage.onerror = function() {
            console.error('Failed to load image:', fullImageUrl);
            modalImage.src = '${pageContext.request.contextPath}/completion_images/image-not-found.png';
        };
        
        // Show the modal
        const myModal = new bootstrap.Modal(document.getElementById('imageModal'));
        myModal.show();
    }
    
    // Function to view complaint details
    function viewComplaint(complaintId) {
        window.location.href = '../view-complaint.jsp?id=' + complaintId;
    }
        $(document).ready(function() {
            loadComplaints();
        });

        function loadComplaints() {
            console.log('Loading complaints for user ID: ' + '<%= session.getAttribute("user_id") %>');
            $.ajax({
                url: '../ComplaintServlet?action=getAssignedComplaints&userId=<%= session.getAttribute("user_id") %>',
                type: 'GET',
                dataType: 'json',
                success: function(response) {
                    console.log('Server response:', response);
                    if (response && response.success) {
                        if (response.complaints && response.complaints.length > 0) {
                            console.log('Found ' + response.complaints.length + ' complaints');
                            displayComplaints(response.complaints);
                        } else {
                            console.log('No complaints found for this technician');
                            $('#complaintsTable').html('<div class="alert alert-info">No complaints assigned to you yet.</div>');
                        }
                    } else {
                        console.error('Error in response:', response);
                        alert('Error: ' + (response ? response.message : 'Unknown error occurred'));
                    }
                },
                error: function(xhr, status, error) {
                    console.error('AJAX Error:', {
                        status: status,
                        error: error,
                        responseText: xhr.responseText
                    });
                    alert('Error loading complaints. Please check console for details.');
                }
            });
        }

        function displayComplaints(complaints) {
            let html = '<div class="table-responsive">' +
                    '<table class="table table-hover align-middle">' +
                    '<thead class="table-light">' +
                    '<tr>' +
                    '<th>Title</th>' +
                    '<th>Location</th>' +
                    '<th>Status</th>' +
                    '<th>Image</th>' +
                    '<th>Completion Image</th>' +
                    '<th>Actions</th>' +
                    '</tr>' +
                    '</thead>' +
                    '<tbody>';

            if (!complaints || complaints.length === 0) {
                html += '<tr><td colspan="6" class="text-center">No complaints found</td></tr>';
            } else {
                complaints.forEach(complaint => {
                    console.log('Processing complaint:', complaint);
                    html += '<tr>';
                    html += '<td>' + (complaint.title || 'No title') + '</td>';
                    html += '<td>' + (complaint.location || '-') + '</td>';
                    
                    // Status with badge
                    let statusClass = 'badge ';
                    switch(complaint.status) {
                        case 'PENDING': statusClass += 'bg-secondary'; break;
                        case 'ASSIGNED': statusClass += 'bg-info'; break;
                        case 'IN_PROGRESS': statusClass += 'bg-primary'; break;
                        case 'COMPLETED': statusClass += 'bg-success'; break;
                        case 'CLOSED': statusClass += 'bg-dark'; break;
                        default: statusClass += 'bg-warning';
                    }
                    html += '<td><span class="' + statusClass + '">' + complaint.status + '</span></td>';
                    
                    // Complaint image
                    html += '<td class="text-center">';
                    if (complaint.image_path) {
                        const imgPath = complaint.image_path.startsWith('/') ? complaint.image_path.substring(1) : complaint.image_path;
                        html += '<img src="${pageContext.request.contextPath}/' + imgPath + '" ' +
                               'class="img-thumbnail" style="max-width: 80px; max-height: 80px; cursor: pointer;" ' +
                               'onclick="showImageModal(\'/' + imgPath + '\')" ' +
                               'alt="Complaint Image" ' +
                               'onerror="this.src=\'${pageContext.request.contextPath}/completion_images/image-not-found.png\';"\>';
                    } else {
                        html += '<span class="text-muted">No image</span>';
                    }
                    html += '</td>';
                    
                    // Completion image (only for COMPLETED/CLOSED)
                    html += '<td class="text-center">';
                    if ((complaint.status === 'COMPLETED' || complaint.status === 'CLOSED')) {
                        if (complaint.completion_image_path) {
                            console.log('Raw completion_image_path from DB:', complaint.completion_image_path);
                            
                            // Extract and clean the filename
                            let filename = complaint.completion_image_path;
                            console.log('Original filename from DB:', filename);
                            
                            // Handle different path formats
                            if (filename.includes('completion_images/')) {
                                filename = filename.split('completion_images/').pop();
                            } else if (filename.includes('completion_images\\')) {
                                filename = filename.split('completion_images\\').pop();
                            } else if (filename.startsWith('/') || filename.startsWith('\\')) {
                                filename = filename.substring(1);
                            }
                            
                            console.log('Cleaned filename:', filename);
                            
                            // Construct the correct path - use absolute path from webapp root
                            const basePath = '${pageContext.request.contextPath}/completion_images/';
                            const fullUrl = basePath + filename;
                            const timestamp = new Date().getTime(); // Cache buster
                            const finalUrl = fullUrl + '?t=' + timestamp;
                            
                            console.log('Loading completion image:', {
                                original: complaint.completion_image_path,
                                cleanedFilename: filename,
                                finalUrl: finalUrl,
                                contextPath: '${pageContext.request.contextPath}'
                            });
                            
                            // Create image element to test loading
                            const testImg = new Image();
                            testImg.onload = function() {
                                console.log('Image loaded successfully:', finalUrl);
                            };
                            testImg.onerror = function() {
                                console.error('Error loading test image:', finalUrl);
                            };
                            testImg.src = finalUrl;
                            
                            // Use the same URL for both thumbnail and modal
                            const modalImageUrl = fullUrl;
                            
                            html += '<div class="position-relative">' +
                                   '<img src="' + finalUrl + '" ' +
                                   'class="img-thumbnail" style="max-width: 80px; max-height: 80px; cursor: pointer;" ' +
                                   'onclick="showImageModal(\'' + modalImageUrl + '\')" ' +
                                   'alt="Completion Image" ' +
                                   'onerror="console.error(\'[IMAGE ERROR] Failed to load: \' + this.src); ' + 
                                   'this.onerror=null; this.src=\'${pageContext.request.contextPath}/completion_images/image-not-found.png?t=' + timestamp + '\';">' +
                                   '</div>';
                        } else {
                            console.log('No completion_image_path for complaint:', complaint.complaint_id);
                            html += '<span class="text-muted">No image</span>';
                        }
                    } else {
                        html += '<span class="text-muted">N/A</span>';
                    }
                    html += '</td>';
                    
                    // Actions
                    html += '<td class="d-flex gap-1">';
                    if (complaint.status !== 'CLOSED') {
                        html += '<button class="btn btn-primary btn-sm" onclick="showStatusModal(' + complaint.complaint_id + ')">Update Status</button>';
                    }
                    html += '</td>';
                    
                    html += '</tr>';
                });
            }
            
            html += '</tbody></table></div>';
            $('#complaintsList').html(html);
            
            // Add click handlers for completion image buttons
            $('.view-completion-image').on('click', function() {
                const imageUrl = $(this).data('image');
                showImageModal(imageUrl);
            });
        }

        function showStatusModal(complaintId) {
            $('#complaintId').val(complaintId);
            $('#statusModal').modal('show');
        }

        function toggleCompletionImage(select) {
            const completionImageDiv = document.getElementById('completionImageDiv');
            const fileInput = document.getElementById('completionImage');
            const preview = document.getElementById('imagePreview');
            
            if (select.value === 'COMPLETED') {
                completionImageDiv.style.display = 'block';
                fileInput.required = true;
                
                // Add image preview functionality
                fileInput.onchange = function(e) {
                    const file = e.target.files[0];
                    if (file) {
                        const reader = new FileReader();
                        reader.onload = function(event) {
                            preview.innerHTML = '<img src="' + event.target.result + '" class="img-thumbnail" style="max-width: 200px;">';
                        };
                        reader.readAsDataURL(file);
                    }
                };
            } else {
                completionImageDiv.style.display = 'none';
                fileInput.required = false;
                fileInput.value = ''; // Clear the file input
                preview.innerHTML = '';
            }
        }

        function updateStatus() {
            const form = document.getElementById('statusForm');
            const status = form.status.value;
            const fileInput = document.getElementById('completionImage');
            const imageError = document.getElementById('imageError');
            
            // Reset error state
            imageError.style.display = 'none';
            
            // Validate if image is required for COMPLETED status
            if (status === 'COMPLETED') {
                if (!fileInput.files || fileInput.files.length === 0) {
                    imageError.style.display = 'block';
                    fileInput.focus();
                    return false;
                }
                
                // Validate file type
                const file = fileInput.files[0];
                const validTypes = ['image/jpeg', 'image/png', 'image/gif'];
                if (!validTypes.includes(file.type)) {
                    imageError.textContent = 'Please upload a valid image (JPEG, PNG, or GIF)';
                    imageError.style.display = 'block';
                    fileInput.focus();
                    return false;
                }
                
                // Validate file size (max 5MB)
                const maxSize = 5 * 1024 * 1024; // 5MB
                if (file.size > maxSize) {
                    imageError.textContent = 'Image size should not exceed 5MB';
                    imageError.style.display = 'block';
                    fileInput.focus();
                    return false;
                }
            }
            
            const formData = new FormData(form);
            formData.append('action', 'update');
            
            // Log form data for debugging
            for (let [key, value] of formData.entries()) {
                console.log(key + ': ' + value);
            }
            
            // Show loading state
            const submitBtn = $('#statusModal').find('.btn-primary');
            const originalBtnText = submitBtn.html();
            submitBtn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Updating...');
            
            $.ajax({
                url: '${pageContext.request.contextPath}/ComplaintServlet',
                type: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                dataType: 'json',
                success: function(response) {
                    console.log('Update status response:', response);
                    if (response && response.success) {
                        $('#statusModal').modal('hide');
                        loadComplaints();
                        // Reset form
                        form.reset();
                        alert('Status updated successfully!');
                    } else {
                        const errorMsg = response && response.message ? response.message : 'Unknown error occurred';
                        console.error('Update failed:', errorMsg);
                        alert('Error: ' + errorMsg);
                    }
                },
                error: function(xhr, status, error) {
                    console.error('AJAX Error:', {
                        status: status,
                        error: error,
                        responseText: xhr.responseText
                    });
                    alert('Error updating status. Please check console for details.');
                },
                complete: function() {
                    // Re-enable button and restore text
                    submitBtn.prop('disabled', false).html(originalBtnText);
                }
            });
        }

        function refreshComplaints() {
            loadComplaints();
        }
    </script>
</body>
</html>
