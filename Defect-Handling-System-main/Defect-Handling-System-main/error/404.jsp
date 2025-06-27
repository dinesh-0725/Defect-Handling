<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>404 - Page Not Found</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5 text-center">
        <h1 class="display-1">404</h1>
        <p class="lead">Oops! The page you're looking for doesn't exist.</p>
        <a href="${pageContext.request.contextPath}/login.jsp" class="btn btn-primary">Back to Login</a>
    </div>
</body>
</html>
