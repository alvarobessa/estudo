#Include 'protheus.ch'
#Include 'FWMBROWSE.CH'
#Include 'FWMVCDEF.CH'
#Include 'colors.ch'
#Include 'topconn.ch'
#Include 'vkey.ch'

/*/{Protheus.doc} RLOJA02
Resultado da Pesquisa
@type function
@version 
@author apbessa
@since 17/07/2022
@return return_type, return_description
/*/

User Function RLOJA02()
    Local aArea  := GetArea()
	Local oBrowse

    oBrowse := FWmBrowse():New()
    oBrowse:SetAlias( 'ZA3' )
    oBrowse:SetDescription('Resultado da Pesquisa')

	oBrowse:AddLegend("!Empty(ZA3->ZA3_NOTACL)", "RED" 	,"Fechado")
	oBrowse:AddLegend("Empty(ZA3->ZA3_NOTACL).AND.ZA3->ZA3_ATENDI=='1'","BLUE","1° Atendimento")
	oBrowse:AddLegend("Empty(ZA3->ZA3_NOTACL).AND.ZA3->ZA3_ATENDI=='2'","YELLOW" ,"2° Atendimento")
  
  
    oBrowse:SetMenuDef('RLOJA02' )
    oBrowse:Activate()

	RestArea(aArea)
	
Return Nil


/*/{Protheus.doc} MenuDef
Cadastro de Resultados
@type function
@version 
@author apbessa
@since 17/07/2022
@return return_type, return_description
/*/

Static Function MenuDef()
    Local aRotina := {}
	
	ADD OPTION aRotina Title 'Visualizar' 					ACTION 'VIEWDEF.RLOJA02' OPERATION 2 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'    					ACTION 'VIEWDEF.RLOJA02' OPERATION 4 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'    					ACTION 'VIEWDEF.RLOJA02' OPERATION 5 ACCESS 144
	ADD OPTION aRotina Title 'Busca Vendas'    				ACTION 'U_RLOJA03()'     OPERATION 3 ACCESS 0
	ADD OPTION aRotina Title 'Gerar Arquivo .cvs'           ACTION 'U_RLOJA01()'     OPERATION 2 ACCESS 0
   

Return aRotina



/*/{Protheus.doc} ModelDef
Cadastro de Resultados
@type function
@version 
@author apbessa
@since 17/07/2022
@return return_type, return_description
/*/

Static Function ModelDef()
    Local oStructZA3 := FwFormStruct(1,'ZA3')
	Local oStructZA4 := FWFormStruct(1,'ZA4')
    Local oModel	 := Nil

	// Adiciona ao modelo uma estrutura de formulario de edicao por campoS
	oModel:= MPFormModel():New('RLOJA02N',/*Pre-Validacao*/,{|oModel| fValidFec(oModel) },/*Commit*/,/*Cancel*/)
	oModel:AddFields( 'ZA3MASTER', /*cOwner*/, oStructZA3 )
	oModel:SetVldActive({|oModel|fZa3Valid(oModel)})
    oModel:SetPrimaryKey({'ZA3_FILIAL','ZA3_FILORI','ZA3_NOTA','ZA3_SERIE'})
	oModel:AddGrid( 'ZA4DETAIL','ZA3MASTER', oStructZA4,/**/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )
	//oModel:GetModel('ZA4DETAIL' ):SetOptional( .T. )
	
	// Faz relaciomaneto entre os compomentes do model
	oModel:SetRelation('ZA4DETAIL', { {'ZA4_FILIAL' ,'xFilial( "ZA3" )'},{'ZA4_FILORI','ZA3_FILORI'},{'ZA4_NOTA','ZA3_NOTA'},{'ZA4_SERIE','ZA3_SERIE'}}, ZA4->( IndexKey(1) )  )
	oModel:GetModel('ZA4DETAIL' ):SetUniqueLine( {'ZA4_FILIAL','ZA4_FILORI','ZA4_NOTA','ZA4_SERIE','ZA4_ITEM'})
	
	//Descrição da tela
	oModel:GetModel('ZA3MASTER'):SetDescription('Resultado da Pesquisa')
	oModel:GetModel('ZA4DETAIL' ):SetDescription( 'Itens da Nota Fiscal'  )


Return oModel


/*/{Protheus.doc} ViewDef
Cadastro de Resultados
@type function
@version 
@author apbessa
@since 17/07/2022
@return return_type, return_description
/*/

Static Function ViewDef()
    Local oStructZA3:= FWFormStruct(2,'ZA3')
	Local oStructZA4:= FWFormStruct(2,'ZA4')
    Local oModel   	:= FWLoadModel('RLOJA02')
    Local oView

	oView:= FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('ZA3MASTER',oStructZA3)	
	oView:AddGrid('ZA4DETAIL' ,oStructZA4)

	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'TOP' , 60 )
	oView:CreateHorizontalBox( 'BOTTOM'   , 40 )

	//Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView('ZA3MASTER','TOP')
	oView:SetOwnerView('ZA4DETAIL','BOTTOM')
	
	oView:AddIncrementField('ZA4DETAIL','ZA4_ITEM')
	
	// Liga a identificacao do componentes
	oView:EnableTitleView('ZA3MASTER')
	oView:EnableTitleView('ZA4DETAIL', 'Itens da Nota Fiscal')
	
	
	oView:EnableControlBar(.T.)
	
		
Return oView

/*/{Protheus.doc} fZa3Valid
Validação da tela 
@type function
@version 1.0
@author apbessa
@since 22/08/2021
/*/

Static Function fZa3Valid(oModel)
	Local lRet     := .T.
	Local cUserPes := RetCodUsr()
	Local cParPesq := SuperGetMv("NI_APRPES",.F.,"000000")
	
	//Atualização
	If oModel:GetOperation() == MODEL_OPERATION_UPDATE 
		oModel:GetModel('ZA4DETAIL'):SetNoInsertLine(.T.)
		If !Empty(ZA3->ZA3_NOTACL) .AND. !Alltrim(cUserPes) $ cParPesq
			oModel:SetErrorMessage('ZA3MASTER',,,,"ATENÇÃO",'Não e possível alterar pesquisa finalizada! Apenas administrador do sistema pode executar alteração')
			lRet := .F.
		EndIf
	EndIf
	
	//Exclusão
	If oModel:GetOperation() == MODEL_OPERATION_DELETE
		If !Empty(ZA3->ZA3_NOTACL) .AND. !Alltrim(cUserPes) $ cParPesq
			oModel:SetErrorMessage('ZA3MASTER',,,,"ATENÇÃO",'Não é possível excluir pesquisa finalizada!Apenas administrador do sistema pode executar exclusão')
			lRet := .F.
		EndIf
	EndIf

Return lRet

Static Function fValidFec(oModel)
	Local lRet      := .T.
	Local oModel    := FWModelActive()
	Local oView     := FWViewActive()

	//Alteração
	If oModel:GetOperation() == 4
		If MsgYesNo("Finalizar atendimento? ")
			If Empty(FWFldGet("ZA3_NOTACL")) 
				MsgAlert("Para finalizar o atendimento, é necessário preenchimento da nota do cliente.", "Nota Cliente")
			EndIf
		EndIf
	EndIf


Return lRet
