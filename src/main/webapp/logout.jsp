<%@page import="com.atlassian.crowd.integration.http.HttpAuthenticator" %>
<%@page import="com.atlassian.crowd.integration.http.HttpAuthenticatorFactory" %>
<% 
	// Url is used to provide a link where user can log back in after logging in.
	final String LOGIN_URL = "http://mycompany.zendesk.com/login/"; 
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Logout from Zendesk</title>
</head>
<body>
	<%
		HttpAuthenticator authenticator = HttpAuthenticatorFactory.getHttpAuthenticator();
		authenticator.logoff(request, response);
		String name = request.getParameter("name");
		String email = request.getParameter("email");
		String kind = request.getParameter("kind");
		String message = request.getParameter("message");
 	%>
 	<% if("error".equals(kind) == false) { %>
 	<h2>You have been succesfully logged out from Zendesk</h2>
 	<% } else { %>
 	<h2>Error occured</h2>
 	<%= message %>
 	<% } %>
 	<a href="<%=LOGIN_URL%>">Click here to login again</a>
</body>
</html>