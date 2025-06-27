<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Error</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <div class="alert alert-danger">
            <h2>An error occurred</h2>
            <p><strong>Message:</strong> ${pageContext.exception.message}</p>
            <p><strong>Exception:</strong> ${pageContext.exception['class'].name}</p>
            <pre>
<% 
if (exception != null) {
    exception.printStackTrace(new java.io.PrintWriter(out)); 
}
%>
            </pre>
        </div>
        <a href="${pageContext.request.contextPath}/login.jsp" class="btn btn-primary">Back to Login</a>
    </div>
</body>
</html>
