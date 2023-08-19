#xcommand TRY  => BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }
#xcommand CATCH [<!oErr!>] => RECOVER [USING <oErr>] <-oErr->
#xcommand FINALLY => ALWAYS

/*
*
*/
function myapi( oDom )
	do case
		case oDom:GetProc() == 'add_product' 			; add_product(oDom)
		case oDom:GetProc() == 'get_data' 				; get_data(oDom)
		case oDom:GetProc() == 'dlg_total' 				; dlg_total(oDom)
		case oDom:GetProc() == 'close_total' 			; close_total(oDom)
		case oDom:GetProc() == 'select_products' 	; select_products(oDom)
										
		otherwise
			oDom:SetError( 'Proc no existe: ' + oDom:GetProc() )
	endcase

return oDom:Send()
/*********/

/*
* add_product
*/
function add_product( oDom )
	local hData := oDom:Get('tableListProducts')['selected']	
	local hInfo	:= {=>}
	local aRows := {}
	local nTotal := 0

	hInfo[ 'codigo' ] 		:= oDom:Get( 'codigo' )
	hInfo[ 'producto' ]   := oDom:Get( 'producto' )
	hInfo[ 'cantidad' ]		:= oDom:Get( 'cantidad' )
	hInfo[ 'precio' ]			:= oDom:Get( 'precio' )
	hInfo[ 'importe' ]	  := ( hInfo[ 'cantidad' ] * hInfo[ 'precio' ] )
	
	Aadd( aRows, { ;
						'id' => ltrim(Str(hb_milliseconds() )), ;
						'codigo' => hInfo[ 'codigo' ], ;
						'producto' => hInfo[ 'producto' ], ;
						'cantidad' => hInfo[ 'cantidad' ], ;
						'precio' => hInfo[ 'precio' ], ;
						'importe' => hInfo[ 'importe' ] ;
					})
		
	oDom:SetScope( 'myscreen' )	//	<<-- cambiamos scope al ID form
	oDom:TableAddData( 'tableOrder', aRows )	
	
return nil
/*********/

/*
* get_data
*/
static function get_data( oDom )
	local hStr 	:= oDom:Get( 'tableOrder' )
	local hData := hStr[ 'data' ]

	_d( 'contenido browse ' , hb_ValToExp( hData ) )
return nil
/*********/

/*
* dlg_total
*/
static function dlg_total( oDom )
	local hInfoTot	:= {=>}
	local hBrowse, hData
	local item
	local hInfo
	local hTotales := {=>}	
	
	// Variables para almacenar los importes de cada item
	local nSubtotal := 0
	local nDescuento := 0
	local nImpuesto := 0
	local nTotal := 0

	// variables para almacenar los totales globales
	local nSubtotalGlobal := 0
	local nDescuentoGlobal := 0
	local nImpuestoGlobal := 0
	local nTotalGlobal := 0

	local cHtml
	local hCfg  := {=>}

	hTotales['subtotal'] := 0

	hBrowse := oDom:Get( 'tableOrder' )
	hData  	:= hBrowse[ 'data' ]
	
	if len( hData ) <= 0		
		oDom:SetJS( "MsgError('No hay datos para procesar ', null, 'Atención')" )
		return nil
	endif

	for each item in hData
		hInfo := {=>}
		hInfo[ 'codigo' ] := item['codigo']
		hInfo[ 'producto' ] := item['producto']
		hInfo[ 'cantidad' ] := item['cantidad']
		hInfo[ 'precio' ] := item['precio']
		nSubtotal := Round( item['cantidad'] * item['precio'], 2)		
		
		nSubtotalGlobal += nSubtotal
		hTotales['subtotal'] 	:= nSubtotalGlobal
	next
	
	hCfg[ 'backdrop' ] 		:= .f.	// .f. el usuario no podrá cerrarla haciendo clic fuera de la misma	
	hCfg[ 'className' ] 	:= 'no-animation' // quitar la animación
	hCfg[ 'onEscape' ] 		:= .f. 	// .t. permite cerrar la ventana modal con tecla esc
	hCfg[ 'title' ] 			:= 'Totales'
	hCfg[ 'size' ] 				:= '30%'	

	cHtml := ULoadHtml( 'dialog\totales.html', hTotales )
	oDom:SetDialog( 'dlg_totales', cHtml, nil, hCfg )

return nil
/*********/


// fin totales

/*
* select_products
*/
function select_products( oDom )
	local cHtml
	local o 		:= {=>}
	local aRows := {}	

	
	o[ 'backdrop' ] 	:= .f.	// .f. el usuario no podrá cerrar el diálogo haciendo clic fuera del diálogo
	o[ 'className' ] 	:= 'no-animation' // quitar la animación
	o[ 'onEscape' ] 	:= .f. 	// .t. permite cerrar la ventana modal con tecla esc	
	o[ 'title' ] 			:= 'Productos'
	o[ 'size' ] 			:= '55%'	

	cHtml := ULoadHtml( 'dialog\selectProducts.html' )
	oDom:SetDialog( 'dlgbrwListProducts', cHtml, nil, o)
	
return nil
/*********/

/*
* listProducts
*/
function listProducts( oDom )
	local aRows := {}
	local aReg	

	local cAlias  := OpenDbf( 'productos.dbf' )	
	
	While (cAlias)->( !Eof() )
		aReg := { 'id'	    	=> hb_RandomInt(1, 100), ;
							'codigo'	 	=> alltrim( (cAlias)->codigo ), ;
						  'producto'  => alltrim( (cAlias)->nombre ), ;
							'precio'    => (cAlias)->precio ;
						}			
			Aadd( aRows, aReg )		
		(cAlias)->( DbSkip() )
	End
	
	(cAlias)->( DbCloseArea() )

return aRows
/*********/

/*
* OpenDbf
*/
static function OpenDbf( cFile, cCdx, cTag )

	static n := 1
	
	local cAlias 		:= 'ALIAS' + ltrim(str(++n))
	local cPathFile, oError	
	
	hb_default( @cFile, 'test.dbf')
	hb_default( @cCdx, '')
	hb_default( @cTag, '')

	cPathFile 	:= AppPathData() + cFile	
	
	TRY

		use ( cPathFile ) shared new alias (cAlias) VIA 'DBFCDX' 
		
		cAlias := alias()
		
		if !empty( cCdx )
		
			SET INDEX TO ( AppPathData() + cCdx )
			
			if !empty( cTag )			
				(cAlias)->( OrdSetFocus( cTag ) )
				
				if (cAlias)->( IndexOrd() ) == 0
					UDo_Error( "Tag doesn't exist " + cTag )
				endif
				
			endif
		endif 
		
	
	CATCH oError 

		Eval( ErrorBlock(), oError )
	
	END

return cAlias
/*********/

/*
* cierra diálogo totalizar
*/
static function close_total( oDom )
	oDom:DialogClose( 'dlg_totales' )
return nil
/***********/