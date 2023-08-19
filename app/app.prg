#include 'lib/uhttpd2/uhttpd2.ch'

#define VK_ESCAPE	27

REQUEST DBFCDX

REQUEST HB_CODEPAGE_ES850  	
REQUEST HB_LANG_ES
REQUEST HB_CODEPAGE_ESWIN 
REQUEST TWEB

function main()

  hb_CdpSelect('ESWIN')	
  hb_LangSelect('ES')
		
	hb_threadStart( @WebServer() )
	
	while inkey(0) != VK_ESCAPE
	end

retu nil 


function WebServer()
	local oServer 	:= Httpd2()

	// Charset UTF8
	//oServer:lUtf8 := .t.
	oServer:SetPort(81)
	
	/* SSL
	oServer:SetPort(443)
	oServer:SetCertificate( 'privkey.pem', 'cert.pem' )
	oServer:SetSSL( .T. )
	*/	

	oServer:SetDirFiles( 'data' )	
	oServer:nSessionDuration :=	3600 //	Default duration session time 3600	
	oServer:bInit := {|hInfo| ShowInfo( hInfo ) }
		
	oServer:Route( '/' , 'main.html' )
	
	IF ! oServer:Run()	
		? "=> Server error:", oServer:cError
		RETU 1
	ENDIF
	
RETURN 0


function ShowInfo( hInfo ) 

	HB_HCaseMatch( hInfo, .f. )

	CConsole '---------------------------------'	
	Console  'Server Harbour9000 was started...'
	Console  '---------------------------------'
	Console  'Version httpd2...: ' + hInfo[ 'version' ]
	Console  'Start............: ' + hInfo[ 'start' ]
	Console  'Port.............: ' + ltrim(str(hInfo[ 'port' ]))
	Console  'OS...............: ' + OS()
	Console  'Harbour..........: ' + VERSION()
	Console  'Build date.......: ' + HB_BUILDDATE()
	Console  'Compiler.........: ' + HB_COMPILER()
	Console  'SSL..............: ' + if( hInfo[ 'ssl' ], 'Yes', 'No' )
	Console  'Trace............: ' + if( hInfo[ 'debug' ], 'Yes', 'No' )
	Console  'Codepage.........: ' + hb_SetCodePage() + '/' + hb_cdpUniID( hb_SetCodePage() )
	Console  'UTF8 (actived)...: ' + if( hInfo[ 'utf8' ], 'Yes', 'No' )
	Console  '---------------------------------'
	Console  'Escape for exit...' 		

return nil

function AppPathData() 		; return hb_dirbase() + 'data\'
function tempFilesPath() ; return hb_dirbase() + 'downloads\'