# Zendesk - Atlassian Crowd JSP (Java Server Pages) integration script
Copyright 2011 Juha Palomäki, juhap iki fi, http://juhap.iki.fi/

This script allows users to logon to Zendesk with Atlassian Crowd authentication. 
Script is implemented as "pure JSP" solution to make installation as easy and 
flexible as possible.

NOTE: No warranties of any kind. Please read and understand the code before you 
take this into use. Errors in this script may for example expose your Zendesk 
account to unauthorized access.

## Installation 

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
        |                    +------ (and other libs the crowd-integration-client depends on)
        +------- login.jsp
        +------- logout.jsp

- Configure the application in your Crowd installation, type is "generic application"
- Configure remote authentication in Zendesk management, using:
  Remote login URL:  http://yourserver/zendesk-crowd/login.jsp
  Remote logout URL: http://yourserver/zendesk-crowd/logout.jsp
- Change the token and url settings in this script to reflect your Zendesk settings