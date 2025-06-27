package com.steelplant.servlets;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/LogoutServlet")
public class LogoutServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger logger = Logger.getLogger(LogoutServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        handleLogout(request, response);
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        handleLogout(request, response);
    }
    
    private void handleLogout(HttpServletRequest request, HttpServletResponse response) throws IOException {
        logger.info("Logout requested");
        
        // Log request URL and headers for debugging
        logger.info("Request URL: " + request.getRequestURL().toString());
        logger.info("Context Path: " + request.getContextPath());
        
        // Invalidate the session
        HttpSession session = request.getSession(false);
        if (session != null) {
            String username = (String) session.getAttribute("username");
            logger.info("Invalidating session for user: " + (username != null ? username : "unknown"));
            session.invalidate();
        } else {
            logger.warning("No active session found to invalidate");
        }
        
        // Set cache control headers
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        
        // Force a full page reload to ensure no cached content is shown
        String contextPath = request.getContextPath();
        String redirectUrl = contextPath + "/login.jsp";
        logger.info("Context Path: " + contextPath);
        logger.info("Redirecting to: " + redirectUrl);
        
        // Clear the buffer and reset the response
        response.reset();
        response.setContentType("text/html");
        
        // Add JavaScript to force a full page reload
        String html = "<html><head><script>"
                   + "window.location.replace('" + redirectUrl + "');"
                   + "</script></head><body>"
                   + "<p>Logging out... Please <a href='" + redirectUrl + "'>click here</a> if you are not redirected.</p>"
                   + "</body></html>";
        
        response.getWriter().write(html);
    }
}
