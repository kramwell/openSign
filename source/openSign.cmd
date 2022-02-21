@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
cd %~dp0

REM set domain ca here!
SET ca_name=domain.local

REM check for open ssl files and get path etc.

REM need to check for admin

IF EXIST "%~dp0openSign.cnf" (
	set OPENSSL_CONF=%~dp0openSign.cnf
) ELSE (
	goto:openSSLnotfound
)

IF EXIST "%~dp0openssl\openssl.exe" (
	IF EXIST "%~dp0openssl\ssleay32.dll" (
		IF EXIST "%~dp0openssl\libeay32.dll" (
			goto:start
		) ELSE (
			goto:openSSLnotfound
		)		
	) ELSE (
		goto:openSSLnotfound
	)	
) ELSE (
	goto:openSSLnotfound
)

pause

REM goto start after checks
goto:start

:start
cls
ECHO.  
ECHO. -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
ECHO.      CA Creator and CSR Signer
ECHO.      v0.64 - KramWell.com
ECHO. -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
ECHO.

ECHO.  (1)	CREATE NEW ROOT CA
REM ECHO.  (x)	RENEW EXISTING ROOT CA
ECHO.  (2)	SIGN A CSR
REM ECHO.  (x)  CONVERT CERTS
ECHO.  (R)	RESTART SCRIPT
ECHO.  (Q)	QUIT

CHOICE /C 12RQ5 /N
IF %ERRORLEVEL% EQU 1 goto sub_create_ca
IF %ERRORLEVEL% EQU 2 goto sub_cd
IF %ERRORLEVEL% EQU 3 goto sub_restart
IF %ERRORLEVEL% EQU 4 goto eof
IF %ERRORLEVEL% EQU 5 goto runAsAdmin
goto:eof

pause

:sub_create_ca
cls

IF EXIST "%~dp0%ca_name%" (
	ECHO folder exists overwrite?
	
	CHOICE /C YN /M "Enter your choice:" 
	IF ERRORLEVEL 2 goto start
	
) ELSE (
	echo folder does not exist, create
	MKDIR "%ca_name%"
)	
	REM here we are creating a new root CA.	
	
	REM generate a private key file
	openssl\openssl.exe genrsa -des3 -out %ca_name%\%ca_name%.key 4096

	openssl\openssl.exe req -x509 -new -nodes -key %ca_name%\%ca_name%.key -days 1825 -out %ca_name%\%ca_name%.pem

	openssl\openssl.exe x509 -outform der -in %ca_name%\%ca_name%.pem -out %ca_name%\%ca_name%.crt
	
	pause
goto:start

:sub_cd

	SET /P sign_cert_name=enter hostname to sign: 

	IF EXIST "%~dp0%sign_cert_name%.csr" (		
		ECHO file exists overwrite?		
		CHOICE /C YN /M "Enter your choice:" 
		IF ERRORLEVEL 2 goto start
	)
	
	ECHO "PASTE CSR FOR %sign_cert_name% HERE- SAVE (ctrl-s) AND CLOSE" > %~dp0%sign_cert_name%.csr
	notepad.exe %~dp0%sign_cert_name%.csr
	
	echo subjectAltName = DNS:%sign_cert_name% > %sign_cert_name%.ext

	openssl\openssl x509 -req -in %sign_cert_name%.csr -CA %ca_name%\%ca_name%.pem -CAkey %ca_name%\%ca_name%.key -CAcreateserial -out %sign_cert_name%.pem -days 365 -sha256 -extfile %sign_cert_name%.ext
	
	openssl\openssl.exe x509 -outform der -in %sign_cert_name%.pem -out %sign_cert_name%.crt
	
	del %sign_cert_name%.ext
	
	ECHO CERT %sign_cert_name% CREATED! in directory %~dp0%sign_cert_name%
	
	pause
goto:start

:sub_restart
	%~n0%~x0
goto:eof

:openSSLnotfound
	Echo OpenSSL components not found. please download files.
	pause
goto:eof

:runAsAdmin

openssl genrsa -out private-key.key 2048

openssl req -new -key private-key.key -out csr.txt

	Echo Please run this program as Admin to continue
	pause
goto:eof

REM next step is creating the csr

:eof
endlocal
EXIT