# login-macOS-app

  In macOS version 10.15, the Network File System can no longer be used. Therefore, files and directories can no longer be linked to students that want to work in 
computer labs.

  This macOS application is built as a "fake login page" that verifies the student's username and password via ldap login. If the user login successfully, this 
application will perform an smb mount to mount(link) the directory owns by the user on to the local lab machine.

  Students who use the lab machine will see as if it is a regular macOS login page.
