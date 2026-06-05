@echo off
setlocal enabledelayedexpansion

rem ===========================================================================
rem               1. ENFORÇAMENTO DE PRIVILÉGIOS DE ADMINISTRADOR
rem ===========================================================================
:CheckPrivileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto GotAdmin
) else (
    goto RequestAdmin
)

:RequestAdmin
echo ======================================================
echo       SOLICITANDO PRIVILÉGIOS DE ADMINISTRADOR...
echo ======================================================
echo.
echo Este script requer direitos de admin para acessar a pasta Program Files.
echo Por favor, clique em "Sim" quando a janela do UAC aparecer.
echo.

set "vbsFile=%temp%\getadmin_%random%.vbs"
echo Set UAC = CreateObject^("Shell.Application"^) > "%vbsFile%"
echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %*", "", "runas", 1 >> "%vbsFile%"

"%vbsFile%"
if exist "%vbsFile%" del "%vbsFile%"
exit /b

:GotAdmin
rem ===========================================================================
rem               2. VARIÁVEIS GLOBAIS E CONFIGURAÇÃO
rem ===========================================================================
set "scriptDir=%~dp0"
set "base=C:\Program Files (x86)\RubinOT 2.0\bin\characterdata"
set "jsonFile=%scriptDir%configs.json"

if not exist "%base%" (
    echo [ERRO] Nao foi possivel encontrar a pasta: "%base%"
    echo Por favor, verifique se o caminho esta correto.
    pause
    exit /b
)

if not exist "%jsonFile%" (
    echo {"configs":{"max_display_limit":"10","language":"pt-BR"},"characterNames":{}} > "%jsonFile%"
)

rem ===========================================================================
rem               3. MENU PRINCIPAL DE NAVEGAÇÃO (COM LOCALIZAÇÃO)
rem ===========================================================================
:Main
cls
cd /d "%base%"

rem --- CARREGAR CONFIGURAÇÕES DO JSON ---
set "maxDisplay=10"
for /f "usebackq tokens=*" %%A in (`powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if ($j.configs.max_display_limit) { $j.configs.max_display_limit } else { '10' }"`) do (
    set "maxDisplay=%%A"
)

set "lang=pt-BR"
for /f "usebackq tokens=*" %%A in (`powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if ($j.configs.language) { $j.configs.language } else { 'pt-BR' }"`) do (
    set "lang=%%A"
)

rem --- TEXTOS DE TRADUÇÃO (DICTIONARY) ---
if "%lang%"=="en-US" (
    set "m_title=RUBINOT 2.0 CHARACTER TOOLKIT"
    set "m_char_util=--- Character Utilities ---"
    set "m_opt_a= [A] Copy All Options (Window Position, Loot, Helper)"
    set "m_opt_c= [C] Copy Master Loot Config to Character"
    set "m_opt_h= [H] Copy RTC Helper From Vocation"
    set "m_gen_util=--- General Utilities ---"
    set "m_opt_l= [L] Update Master Loot Config"
    set "m_opt_u= [U] Export Character Helper to Vocation Master"
    set "m_opt_m= [M] Manage Character Folder Aliases/Nickname"
    set "m_opt_v= [V] View Limit Configuration (Currently: %maxDisplay%)"
    set "m_opt_g= [G] Change Language / Alterar Idioma (Currently: %lang%)"
    set "m_opt_x= [X] Exit Script"
    set "m_select=Select an operation: "
    set "m_no_logs=[No Logs]"
    set "m_active=[Active: "
    set "m_no_nick=No Nick Defined"
    set "m_refresh=[R] Refresh List"
) else (
    set "m_title=PAINEL DE FERRAMENTAS RECURSOS RUBINOT 2.0"
    set "m_char_util=--- Utilitarios de Personagem ---"
    set "m_opt_a= [A] Copiar Todas Opcoes (Posicao de Tela, Loot, Helper)"
    set "m_opt_c= [C] Copiar Master Loot Config para o Personagem"
    set "m_opt_h= [H] Copiar RTC Helper de uma Vocacao"
    set "m_gen_util=--- Utilitarios Gerais ---"
    set "m_opt_l= [L] Atualizar Pasta Master Loot"
    set "m_opt_u= [U] Exportar Helper de Personagem para Master Vocacao"
    set "m_opt_m= [M] Gerenciar Apelidos/Nomes das Pastas"
    set "m_opt_v= [V] Configurar Limite de Exibicao (Atual: %maxDisplay%)"
    set "m_opt_g= [G] Alterar Idioma / Change Language (Atual: %lang%)"
    set "m_opt_x= [X] Sair do Script"
    set "m_select=Selecione uma operacao: "
    set "m_no_logs=[Sem Registros]"
    set "m_active=[Ativo em: "
    set "m_no_nick=Sem Apelido"
    set "m_refresh=[R] Atualizar Lista"
)

echo ======================================================
echo           %m_title%
echo ======================================================
echo.
echo %m_char_util%
echo %m_opt_a%
echo %m_opt_c%
echo %m_opt_h%
echo.
echo %m_gen_util%
echo %m_opt_l%
echo %m_opt_u%
echo %m_opt_m%
echo %m_opt_v%
echo %m_opt_g%
echo.
echo ------------------------------------------------------
echo %m_opt_x%
echo ======================================================
set /p "choice=%m_select%"

if /i "%choice%"=="A" goto BuildListing
if /i "%choice%"=="C" goto BuildListing
if /i "%choice%"=="H" goto BuildListing
if /i "%choice%"=="L" goto BuildListing
if /i "%choice%"=="U" goto BuildListing
if /i "%choice%"=="M" goto BuildListing
if /i "%choice%"=="V" goto ConfigDisplayLimit
if /i "%choice%"=="G" goto ConfigLanguage
if /i "%choice%"=="X" exit
goto Main


rem ===========================================================================
rem               4. MOTOR DE ESCANEAMENTO POR WHITELIST E ORDENAÇÃO
rem ===========================================================================
:BuildListing
set "manifest=%temp%\rubinot_sync_%random%.txt"
if exist "%manifest%" del "%manifest%"

rem --- LÊ DIRETAMENTE AS DATAS DOS ARQUIVOS sellAllWhitelist.json ---
for /f "tokens=*" %%D in ('dir /ad /b') do (
    set "fileDate=00/00/0000"
    set "fileTime=00:00"
    set "sortKey=00000000000000"
    
    if exist "%%D\sellAllWhitelist.json" (
        for /f "tokens=1,2" %%A in ('dir "%%D\sellAllWhitelist.json" /t:w ^| findstr /R /C:"^[0-9]"') do (
            set "fileDate=%%A"
            set "fileTime=%%B"
            set "d=%%A"
            set "t=%%B"
            set "sortKey=!d:~6,4!!d:~3,2!!d:~0,2!!t:~0,2!!t:~3,2!"
        )
    )
    echo !sortKey!^|%%D^|!fileDate! !fileTime!>>"%manifest%"
)

set count=0
for /f "tokens=1,2,3 delims=|" %%I in ('sort /r "%manifest%"') do (
    if !count! LSS %maxDisplay% (
        set /a count+=1
        set "folder[!count!]=%%J"
        set "timestamp=%%K"
        
        set "currAlias="
        set "PS_KEY=%%J"
        for /f "usebackq tokens=*" %%A in (`powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; $k = $env:PS_KEY; if ($j.characterNames.PSObject.Properties[$k]) { $j.characterNames.$k } else { '' }"`) do (
            set "currAlias=%%A"
        )
        
        if "!currAlias!"=="" (
            set "currAlias=%m_no_nick%"
        )
        
        if "!timestamp!"=="00/00/0000 00:00" (
            set "timeStr=%m_no_logs%"
        ) else (
            set "timeStr=%m_active%%%K]"
        )
        
        set "folder_meta[!count!]=%%J (!currAlias!)  ->  !timeStr!"
    )
)
if exist "%manifest%" del "%manifest%"

rem --- DIRECIONAMENTO DAS ROTINAS ---
if /i "%choice%"=="A" goto CopyAllOptions
if /i "%choice%"=="C" goto GlobalToCharLoot
if /i "%choice%"=="L" goto FetchToGlobalLoot
if /i "%choice%"=="H" goto VocationMenu
if /i "%choice%"=="U" goto BackupCharHelperToVoc
if /i "%choice%"=="M" goto ManageAliases
goto Main


rem ===========================================================================
rem               5. CONTROLADORES DE AÇÃO (MÓDULOS)
rem ===========================================================================

rem --- MÓDULO [A]: CLONAGEM TOTAL DE PERFIL ---
:CopyAllOptions
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo       COPY ALL OPTIONS (WINDOWS, LOOT, HELPER)
    echo ======================================================
    echo.
    echo This action will completely replace the destination's layouts,
    echo hotkeys, windows, loot systems, and helpers with the source.
    echo.
    set "p_src=Select SOURCE folder to copy FROM (1-%count%, R to Refresh or B to Back): "
    set "p_dst=Select DESTINATION folder to overwrite (1-%count%): "
    set "m_err1=[!] Invalid selection."
    set "m_err2=[!] Source and Destination cannot be the same."
    set "m_run=Cloning absolute profile configuration..."
) else (
    echo ======================================================
    echo       COPIAR TODAS OPCOES (TELAS, LOOT, HELPER)
    echo ======================================================
    echo.
    echo Esta acao ira substituir completamente os layouts, hotkeys,
    echo janelas, sistemas de loot e helpers do destino pelos da origem.
    echo.
    set "p_src=Selecione a pasta de ORIGEM (1-%count%, R para Atualizar ou B para Voltar): "
    set "p_dst=Selecione a pasta de DESTINO que sera sobrescrita (1-%count%): "
    set "m_err1=[!] Selecao invalida."
    set "m_err2=[!] A Origem e o Destino nao podem ser iguais."
    set "m_run=Clonando configuracao absoluta do perfil..."
)

for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo [B] Back/Voltar
echo.
set /p "srcChoice=%p_src%"

if /i "%srcChoice%"=="B" goto Main
if /i "%srcChoice%"=="R" goto BuildListing
for %%F in ("!srcChoice!") do set "src=!folder[%%~F]!"
if "!src!"=="" (echo %m_err1% & pause & goto CopyAllOptions)

echo.
set /p "destChoice=%p_dst%"
for %%F in ("!destChoice!") do set "dst=!folder[%%~F]!"
if "!dst!"=="" (echo %m_err1% & pause & goto CopyAllOptions)

if "!src!"=="!dst!" (
    echo %m_err2%
    pause & goto CopyAllOptions
)

echo.
echo %m_run%
robocopy "!src!" "!dst!" /MIR /Z /ETA
goto EndAction


rem --- MÓDULO [C]: COPIAR CONFIGURAÇÃO MASTER LOOT PARA PERSONAGEM ---
:GlobalToCharLoot
cls
set "lootSrcDir=%scriptDir%loot"
set "masterLootFile1=%lootSrcDir%\lootBlackWhitelist.json"
set "masterLootFile2=%lootSrcDir%\sellAllWhitelist.json"

if "%lang%"=="en-US" (
    echo ======================================================
    echo       COPY MASTER LOOT CONFIG TO CHARACTER
    echo ======================================================
    echo.
    set "m_no_mst=[ERROR] No master files found in global toolkit folder: "
    set "p_tgt=Select target character folder to update (1-%count%, R to Refresh or B to Back): "
    set "m_err1=[!] Invalid selection."
    set "m_ok1=[+] Successfully applied: "
    set "m_fail=[!] Deployment failed. Master files missing during operation."
    set "m_success=[SUCCESS] Selected character configuration updated from global toolkit."
) else (
    echo ======================================================
    echo       COPIAR MASTER LOOT CONFIG PARA PERSONAGEM
    echo ======================================================
    echo.
    set "m_no_mst=[ERRO] Arquivos master nao encontrados na pasta global: "
    set "p_tgt=Selecione o personagem alvo para atualizar (1-%count%, R para Atualizar ou B para Voltar): "
    set "m_err1=[!] Selecao invalida."
    set "m_ok1=[+] Aplicado com sucesso: "
    set "m_fail=[!] Falha na implantacao. Arquivos master sumiram durante a operacao."
    set "m_success=[SUCESSO] Configuracao do personagem atualizada com base no master global."
)

if not exist "%masterLootFile1%" if not exist "%masterLootFile2%" (
    echo %m_no_mst%"%lootSrcDir%"
    pause & goto Main
)

for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo [B] Back/Voltar
echo.
set /p "destChoice=%p_tgt%"

if /i "%destChoice%"=="B" goto Main
if /i "%destChoice%"=="R" goto BuildListing
for %%F in ("!destChoice!") do set "dstFolder=!folder[%%~F]!"
if "!dstFolder!"=="" (echo %m_err1% & pause & goto GlobalToCharLoot)

echo.
set "copiedLoot=0"
if exist "%masterLootFile1%" (
    copy /y "%masterLootFile1%" "%base%\!dstFolder!\"
    echo %m_ok1%lootBlackWhitelist.json
    set "copiedLoot=1"
)
if exist "%masterLootFile2%" (
    copy /y "%masterLootFile2%" "%base%\!dstFolder!\"
    echo %m_ok1%sellAllWhitelist.json
    set "copiedLoot=1"
)

if "!copiedLoot!"=="0" (
    echo %m_fail%
) else (
    echo %m_success%
)
goto EndAction


rem --- MÓDULO [L]: PUXAR LOOT DE UM PERSONAGEM PARA O REPOSITÓRIO MASTER ---
:FetchToGlobalLoot
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo       UPDATE MASTER LOOT CONFIG (FETCH TO GLOBAL)
    echo ======================================================
    echo.
    set "p_fch=Select character folder to fetch config FROM (1-%count%, R to Refresh or B to Back): "
    set "m_err1=[!] Invalid selection."
    set "m_ok2=[+] Successfully fetched: "
    set "m_none=[!] No configuration files found inside the selected character folder."
    set "m_upd=[SUCCESS] Global Master Loot folder config updated."
) else (
    echo ======================================================
    echo       ATUALIZAR MASTER LOOT CONFIG (PULL PARA GLOBAL)
    echo ======================================================
    echo.
    set "p_fch=Selecione o personagem de onde extrair a config (1-%count%, R para Atualizar ou B para Voltar): "
    set "m_err1=[!] Selecao invalida."
    set "m_ok2=[+] Extraido com sucesso: "
    set "m_none=[!] Nenhum arquivo de config encontrado na pasta do personagem selecionado."
    set "m_upd=[SUCESSO] Configuracao da pasta Global Master Loot atualizada."
)

for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo [B] Back/Voltar
echo.
set /p "srcChoice=%p_fch%"

if /i "%srcChoice%"=="B" goto Main
if /i "%srcChoice%"=="R" goto BuildListing
for %%F in ("!srcChoice!") do set "srcFolder=!folder[%%~F]!"
if "!srcFolder!"=="" (echo %m_err1% & pause & goto FetchToGlobalLoot)

set "lootDestDir=%scriptDir%loot"
set "charLootFile1=%base%\!srcFolder!\lootBlackWhitelist.json"
set "charLootFile2=%base%\!srcFolder!\sellAllWhitelist.json"

if not exist "%lootDestDir%" mkdir "%lootDestDir%"

echo.
set "foundLoot=0"
if exist "%charLootFile1%" (
    copy /y "%charLootFile1%" "%lootDestDir%\"
    echo %m_ok2%lootBlackWhitelist.json
    set "foundLoot=1"
)
if exist "%charLootFile2%" (
    copy /y "%charLootFile2%" "%lootDestDir%\"
    echo %m_ok2%sellAllWhitelist.json
    set "foundLoot=1"
)

if "!foundLoot!"=="0" (
    echo %m_none%
) else (
    echo %m_upd%
)
goto EndAction


rem --- MÓDULO [H]: INJEÇÃO DE HELPER POR VOCAÇÃO ---
:VocationMenu
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo           SELECT RTC HELPER SOURCE VOCATION
    echo ======================================================
    echo.
    echo [1] Druid     [2] Monk     [3] Knight
    echo [4] Paladin   [5] Sorcerer [B] Back to Main Menu
    echo.
    set "p_voc=Select vocation (1-5 or B): "
    set "m_err1=[!] Invalid selection."
    set "m_miss=[ERROR] Expected path missing: "
    set "m_title_dst=Select Destination Character Folder:"
    set "p_hdst=Select target character folder number (1-%count%, R to Refresh): "
    set "m_dep=Deploying helper setting to destination..."
) else (
    echo ======================================================
    echo           SELECIONE A VOCACAO DE ORIGEM DO RTC HELPER
    echo ======================================================
    echo.
    echo [1] Druid     [2] Monk     [3] Knight
    echo [4] Paladin   [5] Sorcerer [B] Voltar ao Menu Principal
    echo.
    set "p_voc=Selecione a vocacao (1-5 ou B): "
    set "m_err1=[!] Selecao invalida."
    set "m_miss=[ERRO] O caminho esperado nao existe: "
    set "m_title_dst=Selecione a Pasta do Personagem de Destino:"
    set "p_hdst=Selecione o numero do personagem alvo (1-%count%, R para Atualizar): "
    set "m_dep=Implantando configuracoes de helper no destino..."
)

set /p "vocChoice=%p_voc%"
if /i "%vocChoice%"=="B" goto Main

set "vocFolder="
if "%vocChoice%"=="1" set "vocFolder=druid"
if "%vocChoice%"=="2" set "vocFolder=monk"
if "%vocChoice%"=="3" set "vocFolder=knight"
if "%vocChoice%"=="4" set "vocFolder=paladin"
if "%vocChoice%"=="5" set "vocFolder=sorcerer"

if "%vocFolder%"=="" (echo %m_err1% & pause & goto VocationMenu)

set "sourceHelper=%scriptDir%%vocFolder%\helper.json"
if not exist "%sourceHelper%" (
    echo %m_miss%"%sourceHelper%"
    pause & goto VocationMenu
)

:VocationDstLoop
cls
echo %m_title_dst%
echo ------------------------------------------------------
for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo.
set /p "helperDest=%p_hdst%"

if /i "%helperDest%"=="R" (
    rem Temporariamente redireciona para atualizar as pastas, depois volta para cá
    goto BuildListing
)

for %%F in ("!helperDest!") do set "targetCharFolder=!folder[%%~F]!"
if "%targetCharFolder%"=="" (echo %m_err1% & pause & goto VocationDstLoop)

echo.
echo %m_dep%
xcopy /Y /F "%sourceHelper%" "%base%\%targetCharFolder%\"
goto EndAction


rem --- MÓDULO [U]: EXPORTAR HELPER DE PERSONAGEM PARA MASTER VOCAÇÃO ---
:BackupCharHelperToVoc
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo       EXPORT CHARACTER HELPER TO VOCATION MASTER
    echo ======================================================
    echo.
    set "p_uch=Select character folder to export helper FROM (1-%count%, R to Refresh or B to Back): "
    set "m_err1=[!] Invalid selection."
    set "m_no_hlp=[ERROR] No helper.json file found inside this character folder."
    set "m_title_voc=Select Target Vocation Master Template to Overwrite:"
    set "p_uvoc=Select vocation template (1-5 or B): "
    set "m_exp=Exporting character helper configuration..."
) else (
    echo ======================================================
    echo       EXPORTAR HELPER DE PERSONAGEM PARA MASTER VOCACAO
    echo ======================================================
    echo.
    set "p_uch=Selecione o personagem de onde exportar o helper (1-%count%, R para Atualizar ou B para Voltar): "
    set "m_err1=[!] Selecao invalida."
    set "m_no_hlp=[ERRO] Nenhum arquivo helper.json encontrado na pasta deste personagem."
    set "m_title_voc=Selecione o Template Master de Vocacao que sera Sobrescrito:"
    set "p_uvoc=Selecione o template de vocacao (1-5 ou B): "
    set "m_exp=Exportando configuracao de helper do personagem..."
)

for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo [B] Back/Voltar
echo.
set /p "srcChoice=%p_uch%"

if /i "%srcChoice%"=="B" goto Main
if /i "%srcChoice%"=="R" goto BuildListing
for %%F in ("!srcChoice!") do set "srcFolder=!folder[%%~F]!"
if "!srcFolder!"=="" (echo %m_err1% & pause & goto BackupCharHelperToVoc)

set "charHelperFile=%base%\!srcFolder!\helper.json"
if not exist "%charHelperFile%" (
    echo %m_no_hlp%
    pause & goto BackupCharHelperToVoc
)

cls
echo %m_title_voc%
echo ------------------------------------------------------
echo [1] Druid     [2] Monk     [3] Knight
echo [4] Paladin   [5] Sorcerer [B] Back/Voltar
echo.
set /p "vocChoice=%p_uvoc%"
if /i "%vocChoice%"=="B" goto Main

set "vocFolder="
if "%vocChoice%"=="1" set "vocFolder=druid"
if "%vocChoice%"=="2" set "vocFolder=monk"
if "%vocChoice%"=="3" set "vocFolder=knight"
if "%vocChoice%"=="4" set "vocFolder=paladin"
if "%vocChoice%"=="5" set "vocFolder=sorcerer"

if "%vocFolder%"=="" (echo %m_err1% & pause & goto BackupCharHelperToVoc)

set "destVocDir=%scriptDir%%vocFolder%"
if not exist "%destVocDir%" mkdir "%destVocDir%"

echo.
echo %m_exp%
copy /y "%charHelperFile%" "%destVocDir%\helper.json"
goto EndAction


rem --- MÓDULO [M]: GERENCIADOR DE APELIDOS ---
:ManageAliases
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo               CHARACTER FOLDER ALIAS MANAGER
    echo ======================================================
    echo.
    set "p_mng=Select folder number to manage (1-%count%, R to Refresh or B to Back): "
    set "m_err1=[!] Invalid selection."
    set "p_name=Enter character name/alias (Leave blank to remove): "
    set "m_sv=[+] Saved nickname linked to Character ID: "
    set "m_cl=[-] Nickname link cleared for Character ID: "
) else (
    echo ======================================================
    echo               GERENCIADOR DE APELIDOS DE PERSONAGEM
    echo ======================================================
    echo.
    set "p_mng=Selecione o numero da pasta para gerenciar (1-%count%, R para Atualizar ou B para Voltar): "
    set "m_err1=[!] Selecao invalida."
    set "p_name=Insira o nome/apelido do personagem (Deixe em branco para remover): "
    set "m_sv=[+] Apelido salvo e vinculado ao ID do Personagem: "
    set "m_cl=[-] Vinculo de apelido removido para o ID do Personagem: "
)

for /l %%X in (1,1,%count%) do (echo [%%X] !folder_meta[%%X]!)
echo %m_refresh%
echo [B] Back/Voltar
echo.
set /p "aliasChoice=%p_mng%"

if /i "%aliasChoice%"=="B" goto Main
if /i "%aliasChoice%"=="R" goto BuildListing
for %%F in ("!aliasChoice!") do set "targetRawFolder=!folder[%%~F]!"
if "%targetRawFolder%"=="" (echo %m_err1% & pause & goto ManageAliases)

echo.
echo ID: %targetRawFolder%
set /p "newAlias=%p_name%"
set "newAlias=%newAlias:"=%"

set "PS_KEY=%targetRawFolder%"
set "PS_VAL=%newAlias%"

if not "%newAlias%"=="" (
    powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if (-not $j) { $j = New-Object PSObject }; if (-not $j.characterNames) { Add-Member -InputObject $j -NotePropertyName 'characterNames' -NotePropertyValue @{} -Force }; $j.characterNames | Add-Member -NotePropertyName $env:PS_KEY -NotePropertyValue $env:PS_VAL -Force; if (-not $j.configs) { Add-Member -InputObject $j -NotePropertyName 'configs' -NotePropertyValue @{} -Force }; $j | ConvertTo-Json | Set-Content '%jsonFile%'"
    echo %m_sv%%targetRawFolder%
) else (
    powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if ($j -and $j.characterNames) { $j.characterNames.PSObject.Properties.Remove($env:PS_KEY) }; $j | ConvertTo-Json | Set-Content '%jsonFile%'"
    echo %m_cl%%targetRawFolder%
)

pause
goto Main


rem --- MÓDULO [V]: CONFIGURAR LIMITE DE EXIBIÇÃO ---
:ConfigDisplayLimit
cls
if "%lang%"=="en-US" (
    echo ======================================================
    echo             CHARACTER DISPLAY LIMIT CONFIG
    echo ======================================================
    echo.
    echo Current view limit is set to: %maxDisplay% characters.
    echo (You can increase this up to 10 characters)
    echo.
    set "p_lim=Enter new view limit (1-10) or press enter to keep current: "
    set "m_inv=[!] Invalid input. Please enter a valid number between 1 and 10."
    set "m_ok=[+] Display limit setting updated successfully."
) else (
    echo ======================================================
    echo             CONFIGURACAO DE LIMITE DE EXIBICAO
    echo ======================================================
    echo.
    echo O limite de exibicao atual e: %maxDisplay% personagens.
    echo (Voce pode aumentar isso para ate 10 personagens)
    echo.
    set "p_lim=Insira o novo limite (1-10) ou pressione enter para manter o atual: "
    set "m_inv=[!] Entrada invalida. Por favor, insira um numero valido entre 1 and 10."
    set "m_ok=[+] Limite de exibicao updated com sucesso."
)

set /p "newLimit=%p_lim%"
if "%newLimit%"=="" goto Main

echo %newLimit%| findstr /R "^[1-9]$ ^10$" >nul
if %errorLevel% neq 0 (
    echo %m_inv%
    pause
    goto ConfigDisplayLimit
)

powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if (-not $j) { $j = New-Object PSObject }; if (-not $j.configs) { Add-Member -InputObject $j -NotePropertyName 'configs' -NotePropertyValue @{} -Force }; $j.configs | Add-Member -NotePropertyName 'max_display_limit' -NotePropertyValue %newLimit% -Force; if (-not $j.characterNames) { Add-Member -InputObject $j -NotePropertyName 'characterNames' -NotePropertyValue @{} -Force }; $j | ConvertTo-Json | Set-Content '%jsonFile%'"
echo %m_ok%
pause
goto Main


rem --- MÓDULO [G]: GERENCIADOR DE IDIOMA DO SCRIPT ---
:ConfigLanguage
cls
echo ======================================================
echo       CHANGE LANGUAGE / ALTERAR IDIOMA
echo ======================================================
echo.
echo [1] English (en-US)
echo [2] Portugues Brasileiro (pt-BR)
echo.
set /p "langChoice=Select/Selecione (1-2): "

set "newLang="
if "%langChoice%"=="1" set "newLang=en-US"
if "%langChoice%"=="2" set "newLang=pt-BR"

if "%newLang%"=="" goto Main

powershell -Command "$j = Get-Content '%jsonFile%' -ErrorAction SilentlyContinue | ConvertFrom-Json; if (-not $j) { $j = New-Object PSObject }; if (-not $j.configs) { Add-Member -InputObject $j -NotePropertyName 'configs' -NotePropertyValue @{} -Force }; $j.configs | Add-Member -NotePropertyName 'language' -NotePropertyValue '%newLang%' -Force; if (-not $j.characterNames) { Add-Member -InputObject $j -NotePropertyName 'characterNames' -NotePropertyValue @{} -Force }; $j | ConvertTo-Json | Set-Content '%jsonFile%'"
goto Main


rem ===========================================================================
rem               6. FINALIZAÇÃO DAS PIPELINES DE AÇÃO
rem ===========================================================================
:EndAction
echo.
if "%lang%"=="en-US" (
    echo ======================================================
    echo Operation Complete.
) else (
    echo ======================================================
    echo Operacao Concluida com Sucesso.
)
pause
goto Main