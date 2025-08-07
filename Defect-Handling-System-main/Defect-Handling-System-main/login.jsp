<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching of login page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0
    response.setDateHeader("Expires", 0); // Proxies
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Steel Plant Detection System - Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .login-container {
            max-width: 400px;
            margin: 100px auto;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .error-message {
            color: red;
            font-size: 0.9em;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-container">
            <h2 class="text-center mb-4">Login</h2>
            <form id="loginForm" action="${pageContext.request.contextPath}/LoginServlet" method="POST">
                <div class="mb-3">
                    <label for="username" class="form-label">Username</label>
                    <input type="text" class="form-control" id="username" name="username" required>
                </div>

                <div class="mb-3">
                    <label for="password" class="form-label">Password</label>
                    <input type="password" class="form-control" id="password" name="password" required>
                </div>

                <div class="mb-3">
                    <button type="submit" class="btn btn-primary w-100">Login</button>
                </div>

                <div class="text-center">
                    <a href="register.jsp">Don't have an account? Register here</a>
                </div>
            </form>
            <div id="errorDiv" class="error-message"></div>
        </div>
    </div>



    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        $(document).ready(function() {
            $('#loginForm').on('submit', function(e) {
                e.preventDefault();
                
                $.ajax({
                    url: 'LoginServlet',
                    type: 'POST',
                    data: $(this).serialize(),
                    success: function(response) {
                        try {
                            var jsonResponse = typeof response === 'string' ? JSON.parse(response) : response;
                            if (jsonResponse.success) {
                                window.location.href = jsonResponse.message;
                            } else {
                                $('#errorDiv').text(jsonResponse.message);
                            }
                        } catch (e) {
                            console.error('Error parsing response:', e);
                            $('#errorDiv').text('An error occurred while processing the response.');
                        }
                    },
                    error: function() {
                        $('#errorDiv').text('An error occurred. Please try again.');
                    }
                });
            });
        });

    </script>
</body>
</html>
