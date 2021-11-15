Attribute VB_Name = "InvNpc"

Option Explicit
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'                        Modulo Inv & Obj
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'Modulo para controlar los objetos y los inventarios.
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
'?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
Public Function TirarItemAlPiso(pos As WorldPos, Obj As Obj, Optional NotPirata As Boolean = True) As WorldPos
On Error GoTo Errhandler


    
    
    Dim NuevaPos As WorldPos
    NuevaPos.x = 0
    NuevaPos.Y = 0
    
    TileLibre pos, NuevaPos, Obj, NotPirata, True
    If NuevaPos.x <> 0 And NuevaPos.Y <> 0 Then
        Call MakeObj(Obj, pos.map, NuevaPos.x, NuevaPos.Y)
    End If
    TirarItemAlPiso = NuevaPos

Exit Function
Errhandler:

End Function

Public Sub NPC_TIRAR_ITEMS(ByRef npc As npc)
On Error Resume Next

    If npc.Invent.NroItems > 0 Then
        Dim i As Byte
        Dim MiObj As Obj
        For i = 1 To MAX_INVENTORY_SLOTS
            If npc.Invent.Object(i).ObjIndex > 0 Then
                MiObj.Amount = npc.Invent.Object(i).Amount
                MiObj.ObjIndex = npc.Invent.Object(i).ObjIndex
                If npc.Invent.Object(i).Prob = 100 Then
                    Call TirarItemAlPiso(npc.pos, MiObj)
                'Probavilidad de dropeo
                ElseIf RandomNumber(1, 100) <= npc.Invent.Object(i).Prob Then
                    Call TirarItemAlPiso(npc.pos, MiObj)
                    Call SendData(SendTarget.ToMap, npc.pos.map, PrepareMessagePlayWave(SND_DROPITEM, npc.pos.x, npc.pos.Y))
                    Exit Sub
                End If
            End If
        Next i
    End If
    
End Sub
Function QuedanItems(ByVal NpcIndex As Integer, ByVal ObjIndex As Integer) As Boolean
On Error Resume Next
'Call LogTarea("Function QuedanItems npcindex:" & NpcIndex & " objindex:" & ObjIndex)

    Dim i As Integer
    If Npclist(NpcIndex).Invent.NroItems > 0 Then
        For i = 1 To MAX_INVENTORY_SLOTS
            If Npclist(NpcIndex).Invent.Object(i).ObjIndex = ObjIndex Then
                QuedanItems = True
                Exit Function
            End If
        Next
    End If
    QuedanItems = False
End Function

''
' Gets the amount of a certain item that an npc has.
'
' @param npcIndex Specifies reference to npcmerchant
' @param ObjIndex Specifies reference to object
' @return   The amount of the item that the npc has
' @remarks This function reads the Npc.dat file
Function EncontrarCant(ByVal NpcIndex As Integer, ByVal ObjIndex As Integer) As Integer
'***************************************************
'Author: Unknown
'Last Modification: 03/09/08
'Last Modification By: Marco Vanotti (Marco)
' - 03/09/08 EncontrarCant now returns 0 if the npc doesn't have it (Marco)
'***************************************************
On Error Resume Next
'Devuelve la cantidad original del obj de un npc

    Dim ln As String, npcfile As String
    Dim i As Integer
    
    npcfile = DatPath & "NPCs.dat"
     
    For i = 1 To MAX_INVENTORY_SLOTS
        ln = GetVar(npcfile, "NPC" & Npclist(NpcIndex).Numero, "Obj" & i)
        If ObjIndex = val(ReadField(1, ln, 45)) Then
            EncontrarCant = val(ReadField(2, ln, 45))
            Exit Function
        End If
    Next
                       
    EncontrarCant = 0

End Function

Sub ResetNpcInv(ByVal NpcIndex As Integer)
On Error Resume Next

    Dim i As Integer
    
    Npclist(NpcIndex).Invent.NroItems = 0
    
    For i = 1 To MAX_INVENTORY_SLOTS
       Npclist(NpcIndex).Invent.Object(i).ObjIndex = 0
       Npclist(NpcIndex).Invent.Object(i).Amount = 0
    Next i
    
    Npclist(NpcIndex).InvReSpawn = 0

End Sub

''
' Removes a certain amount of items from a slot of an npc's inventory
'
' @param npcIndex Specifies reference to npcmerchant
' @param Slot Specifies reference to npc's inventory's slot
' @param antidad Specifies amount of items that will be removed
Sub QuitarNpcInvItem(ByVal NpcIndex As Integer, ByVal Slot As Byte, ByVal Cantidad As Integer)
'***************************************************
'Author: Unknown
'Last Modification: 03/09/08
'Last Modification By: Marco Vanotti (Marco)
' - 03/09/08 Now this sub checks that te npc has an item before respawning it (Marco)
'***************************************************
Dim ObjIndex As Integer
Dim iCant As Integer
ObjIndex = Npclist(NpcIndex).Invent.Object(Slot).ObjIndex

    'Quita un Obj
    If ObjData(Npclist(NpcIndex).Invent.Object(Slot).ObjIndex).Crucial = 0 Then
        Npclist(NpcIndex).Invent.Object(Slot).Amount = Npclist(NpcIndex).Invent.Object(Slot).Amount - Cantidad
        
        If Npclist(NpcIndex).Invent.Object(Slot).Amount <= 0 Then
            Npclist(NpcIndex).Invent.NroItems = Npclist(NpcIndex).Invent.NroItems - 1
            Npclist(NpcIndex).Invent.Object(Slot).ObjIndex = 0
            Npclist(NpcIndex).Invent.Object(Slot).Amount = 0
            If Npclist(NpcIndex).Invent.NroItems = 0 And Npclist(NpcIndex).InvReSpawn <> 1 Then
               Call CargarInvent(NpcIndex) 'Reponemos el inventario
            End If
        End If
    Else
        Npclist(NpcIndex).Invent.Object(Slot).Amount = Npclist(NpcIndex).Invent.Object(Slot).Amount - Cantidad
        
        If Npclist(NpcIndex).Invent.Object(Slot).Amount <= 0 Then
            Npclist(NpcIndex).Invent.NroItems = Npclist(NpcIndex).Invent.NroItems - 1
            Npclist(NpcIndex).Invent.Object(Slot).ObjIndex = 0
            Npclist(NpcIndex).Invent.Object(Slot).Amount = 0
            
            If Not QuedanItems(NpcIndex, ObjIndex) Then
                'Check if the item is in the npc's dat.
                iCant = EncontrarCant(NpcIndex, ObjIndex)
                If iCant Then
                    Npclist(NpcIndex).Invent.Object(Slot).ObjIndex = ObjIndex
                    Npclist(NpcIndex).Invent.Object(Slot).Amount = iCant
                    Npclist(NpcIndex).Invent.NroItems = Npclist(NpcIndex).Invent.NroItems + 1
                End If
            End If
            
            If Npclist(NpcIndex).Invent.NroItems = 0 And Npclist(NpcIndex).InvReSpawn <> 1 Then
               Call CargarInvent(NpcIndex) 'Reponemos el inventario
            End If
        End If
    
    
    
    End If
End Sub

Sub CargarInvent(ByVal NpcIndex As Integer)

'Vuelve a cargar el inventario del npc NpcIndex
Dim LoopC As Integer
Dim ln As String
Dim npcfile As String

npcfile = DatPath & "NPCs.dat"

Npclist(NpcIndex).Invent.NroItems = val(GetVar(npcfile, "NPC" & Npclist(NpcIndex).Numero, "NROITEMS"))

For LoopC = 1 To Npclist(NpcIndex).Invent.NroItems
    ln = GetVar(npcfile, "NPC" & Npclist(NpcIndex).Numero, "Obj" & LoopC)
    Npclist(NpcIndex).Invent.Object(LoopC).ObjIndex = val(ReadField(1, ln, 45))
    Npclist(NpcIndex).Invent.Object(LoopC).Amount = val(ReadField(2, ln, 45))
    
Next LoopC

End Sub


