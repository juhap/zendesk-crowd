<%  /*
	Zendesk - Atlassian Crowd JSP (Java Server Pages) integration script
	Copyright 2011 Juha Palomäki, http://juhap.iki.fi/
	For latest version, see: https://github.com/juhap/zendesk-crowd
	
	This script allows users to logon to Zendesk with Atlassian Crowd authentication. 
	Script is implemented as "pure JSP" solution to make installation as easy and 
	flexible as possible.
	
	NOTE: No warranties of any kind. Please read and understand the code before you 
	take this into use. Errors in this script may for example expose your Zendesk 
	account to unauthorized access
	
	Installation: 
	- Create the folder structure in your app servers (for example Tomcat) deploy directory
	  and copy files to appropriate plases:
	zendesk-crowd
	        |
	        +------- WEB-INF
	        |           +------ web.xml
	        |           +------ classes
	        |           |          +---- crowd-ehcache.xml
	        |           |          +---- crowd.properties  (these come from your crowd installation)
	        |           +------ lib
	        |                    +------ crowd-integration-client-x.x.x.jar 
	        |                    +------ (and other required libs)
            +------- login.jsp
            +------- logout.jsp
	
	- Configure the application in your CROWD installation, type is "generic application"
	- Configure remote authentication in Zendesk management, using:
	  Remote login URL:  http://yourserver/zendesk-crowd/login.jsp
	  Remote logout URL: http://yourserver/zendesk-crowd/logout.jsp
	- Change the token and url settings in this script to reflect your Zendesk settings
               
	*/ 
 %>
<%@page import="java.util.*" %>
<%@page import="com.atlassian.crowd.integration.soap.SOAPPrincipal" %>
<%@page import="com.atlassian.crowd.integration.soap.SOAPAttribute" %>
<%@page import="com.atlassian.crowd.integration.http.HttpAuthenticator" %>
<%@page import="com.atlassian.crowd.integration.http.HttpAuthenticatorFactory" %>
<%@page import="com.atlassian.crowd.model.user.UserConstants"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="java.io.UnsupportedEncodingException"%>
<%@page import="org.apache.commons.httpclient.util.URIUtil"%>
<%@page import="org.apache.commons.httpclient.URIException"%>
<%@page import="org.apache.commons.logging.LogFactory"%>
<%@page import="org.apache.commons.logging.Log"%>
<%@page import="java.security.MessageDigest"%>
<%@page import="java.security.NoSuchAlgorithmException"%>
<%@page import="org.apache.commons.codec.binary.Hex"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Login to Zendesk</title>
</head>
<body>
<%
	// Configuration
	//
	// Set the following values according to your Zendesk security settings 
	final String ZENDESK_TOKEN = "2x6nO67v4SQ6mozOksoVMasEaRz3FqrWzGDcmbg9s8YLXClQ";								  
	final String ZENDESK_RETURN_URL = "http://tofuture.zendesk.com/access/remote/";
	//
	// (See code for setting up external_id and name handling)
	// End of configuration
 %>
<%!
	public String createZendeskDigest(String name, String external_id, String organization, String email, String timestamp, String token) {
		StringBuffer data = new StringBuffer();
		data.append(emptyIfNull(name));
		data.append(emptyIfNull(email));
		data.append(emptyIfNull(external_id));
		data.append(emptyIfNull(organization));		
		data.append(token);
		data.append(timestamp);
		
		try {
			byte[] msg = data.toString().getBytes("UTF-8");
			MessageDigest md = MessageDigest.getInstance("MD5");
			byte[] digest = md.digest(msg);
			return new String(Hex.encodeHex(digest));
		}
		catch(UnsupportedEncodingException e) {
			throw new RuntimeException(e);
		}
		catch(NoSuchAlgorithmException e) {
			throw new RuntimeException(e);
		}
			
	}
	
	public String getRedirectUrl(SOAPPrincipal principal, String timestamp, String return_to, String zendeskUrl, String zendeskToken) {
		// Read authentication information
		String email = principal.getAttribute(UserConstants.EMAIL).getValues()[0];
		String displayname = principal.getAttribute(UserConstants.DISPLAYNAME).getValues()[0];
		String firstname = principal.getAttribute(UserConstants.FIRSTNAME).getValues()[0];
		String lastname = principal.getAttribute(UserConstants.LASTNAME).getValues()[0];
		// Organization or externalId are not specified. Since they are null, they are  excluded 
		// from the redirect url.
		String organization = null;
		String externalId = null;
		
		// Name variable is the name that gets passed to Zendesk. Normally you could probably use
		// the "displayName" attribute from principal, but in our case that is last + first, while
		// we want first + last.) 			
		String name = firstname + " " + lastname;	

		StringBuffer url = new StringBuffer();
		// Strip trailing / from the url
		if(zendeskUrl.endsWith("/")) {
			url.append(zendeskUrl.substring(0, zendeskUrl.length()-1));
		} else {
			url.append(zendeskUrl);
		}		
		if(name != null) {
			url.append("?name=" + encode(name));
		}
		if(email != null) {
			url.append("&email=" + encode(email));
		}		
		if(organization != null) {
			url.append("&organization=" + encode(organization));
		}
		if(return_to != null) {
			url.append("&return_to=" + encode(return_to));
		}
		url.append("&timestamp=" + timestamp);
		url.append("&hash=" + createZendeskDigest(
			name,
			externalId, 
			organization, 
			email, 
			timestamp, 
			zendeskToken));
			
		return url.toString();
	}
	
	// Return empty string if value is null, otherwise value
	private String emptyIfNull(String value) {
		return value != null ? value : "";
	}
	
	// Helper for handling URL encoding
	private String encode(String value) {
		try {
			return URIUtil.encodeWithinQuery(value);
		} catch(URIException e) {
			throw new RuntimeException(e);
		}
	}	 
 %>

<%
	Log log = LogFactory.getLog("zendesk-crowd");
	String timestamp = request.getParameter("timestamp");
	if(timestamp == null || timestamp.length() == 0) {
		timestamp = Long.toString(System.currentTimeMillis());
	}
	String returnTo = request.getParameter("return_to");
	if(returnTo == null || returnTo.length() == 0) {
		returnTo = (String) session.getAttribute("returnTo");		
	} else {
		session.setAttribute("returnTo", returnTo);
	}
	String username = request.getParameter("username");
	String password = request.getParameter("password");
	String errorMsg = null;
	if(username == null) {
		username = "";
	}	
	final HttpAuthenticator authenticator = HttpAuthenticatorFactory.getHttpAuthenticator();	
	// Check if we can authenticate via SSO
	if(authenticator.isAuthenticated(request, response)) {		
        String url = getRedirectUrl(        	 
        	authenticator.getPrincipal(request),
        	timestamp,
        	returnTo,
        	ZENDESK_RETURN_URL,
        	ZENDESK_TOKEN);
        	
        log.debug("Successfull SSO authentication, redirecting to url " + url);
        response.sendRedirect(url);
        
        return;        	     
    // Check with username and password   	    
	} else if(username != null && password != null) {
		try {
			authenticator.authenticate(request, response, username, password);
			SOAPPrincipal principal = authenticator.getPrincipal(request);
			String url = getRedirectUrl(
				authenticator.getPrincipal(request),
				timestamp,
				returnTo,
				ZENDESK_RETURN_URL,
				ZENDESK_TOKEN);
		
			log.debug("Successfull authentication with username and password, redirecting to url " + url);		        	
        	response.sendRedirect(url);
        	
        	return;
        
		} catch(Exception e) {
			// Error occurred during login. Also wrong username/password combination throws
			// an exception.
			errorMsg = e.getMessage();
			log.error("Error occurred while authenticating with crowd.", e);
		}
	}	
 %>
<form method="post" action="login.jsp">
	<fieldset>
		<legend>Zendesk login</legend>
		<% if(errorMsg != null) { %>
			Error: <%=errorMsg %>
		<% } %>
		<strong>Username</strong><br/>
		<input type="text" size="30" name="username" autofocus /><br/>
		<strong>Password</strong><br/>
		<input type="password" size="30" name="password" /><br/>
		<button type="submit">Login</button>
	</fieldset>
</form>
</body>
</html>
